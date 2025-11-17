package billing

import (
	"context"
	"database/sql"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type Service struct {
	DB *sql.DB
}

func NewService(db *sql.DB) *Service {
	return &Service{DB: db}
}

func (s *Service) ListActiveProducts(ctx context.Context) ([]Product, error) {
	rows, err := s.DB.QueryContext(ctx, `
SELECT id, code, name, COALESCE(description,''), provider, COALESCE(external_id,''), currency, amount_cents, interval, COALESCE(metadata, '{}'::jsonb)
FROM billing_products
WHERE active = TRUE
ORDER BY amount_cents ASC, created_at ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var products []Product
	for rows.Next() {
		var p Product
		var metadata json.RawMessage
		if err := rows.Scan(&p.ID, &p.Code, &p.Name, &p.Description, &p.Provider, &p.ExternalID, &p.Currency, &p.AmountCents, &p.Interval, &metadata); err != nil {
			return nil, err
		}
		p.Metadata = metadata
		products = append(products, p)
	}
	return products, rows.Err()
}

func (s *Service) CurrentSubscription(ctx context.Context, userID uuid.UUID) (*SubscriptionSnapshot, error) {
	const query = `
SELECT p.code, us.status, us.provider, us.current_period_end
FROM user_subscriptions us
LEFT JOIN billing_products p ON p.id = us.product_id
WHERE us.user_id = $1
ORDER BY us.updated_at DESC
LIMIT 1;
`
	var snap SubscriptionSnapshot
	err := s.DB.QueryRowContext(ctx, query, userID).Scan(&snap.ProductCode, &snap.Status, &snap.Provider, &snap.CurrentPeriodEnd)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrSubscriptionNotFound
		}
		return nil, err
	}
	return &snap, nil
}

func (s *Service) ApplySubscriptionUpdate(ctx context.Context, update SubscriptionUpdate) error {
	if !update.Provider.Valid() {
		return ErrInvalidProvider
	}
	metaJSON := mapToJSON(update.Metadata)

	tx, err := s.DB.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	productID, err := ensureProduct(ctx, tx, update)
	if err != nil {
		return err
	}

	if err := upsertSubscription(ctx, tx, update, productID, metaJSON); err != nil {
		return err
	}

	if err := recordPaymentEvent(ctx, tx, update, metaJSON); err != nil {
		return err
	}

	if update.EntitlementCode != "" {
		if err := syncEntitlement(ctx, tx, update); err != nil {
			return err
		}
	}

	if err := tx.Commit(); err != nil {
		return err
	}
	return nil
}

func ensureProduct(ctx context.Context, tx *sql.Tx, update SubscriptionUpdate) (uuid.UUID, error) {
	const selectQuery = `SELECT id FROM billing_products WHERE code = $1 LIMIT 1`
	var productID uuid.UUID
	err := tx.QueryRowContext(ctx, selectQuery, update.ProductCode).Scan(&productID)
	if err == nil {
		return productID, nil
	}
	if err != sql.ErrNoRows {
		return uuid.Nil, err
	}

	const insertQuery = `
INSERT INTO billing_products (code, name, description, provider, external_id, currency, amount_cents, interval, metadata)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,COALESCE($9,'{}'::jsonb))
RETURNING id`
	var meta sql.NullString
	if len(update.Metadata) > 0 {
		metaBytes, _ := json.Marshal(update.Metadata)
		meta.String = string(metaBytes)
		meta.Valid = true
	}
	if err := tx.QueryRowContext(ctx, insertQuery,
		update.ProductCode,
		update.ProductName,
		update.ProductDescription,
		update.Provider,
		update.ExternalProductID,
		update.Currency,
		update.AmountCents,
		update.Interval,
		meta,
	).Scan(&productID); err != nil {
		return uuid.Nil, err
	}
	return productID, nil
}

func upsertSubscription(ctx context.Context, tx *sql.Tx, update SubscriptionUpdate, productID uuid.UUID, metadata json.RawMessage) error {
	const query = `
INSERT INTO user_subscriptions (
	user_id, product_id, provider, status, started_at, current_period_end, cancel_at, canceled_at,
	external_customer_id, external_subscription_id, metadata, updated_at
) VALUES (
	$1,$2,$3,$4,COALESCE($5, now()),$6,$7,$8,$9,$10,COALESCE($11,'{}'::jsonb), now()
) ON CONFLICT (provider, external_subscription_id)
DO UPDATE SET
	product_id = EXCLUDED.product_id,
	status = EXCLUDED.status,
	current_period_end = EXCLUDED.current_period_end,
	cancel_at = EXCLUDED.cancel_at,
	canceled_at = EXCLUDED.canceled_at,
	external_customer_id = EXCLUDED.external_customer_id,
	metadata = EXCLUDED.metadata,
	updated_at = EXCLUDED.updated_at
RETURNING id;
`
	var startedAt *time.Time
	if update.Status == StatusTrialing && update.CurrentPeriodEnd != nil {
		now := time.Now()
		startedAt = &now
	}
	_, err := tx.ExecContext(ctx, query,
		update.UserID,
		productID,
		update.Provider,
		update.Status,
		startedAt,
		update.CurrentPeriodEnd,
		update.CancelAt,
		update.CanceledAt,
		update.ExternalCustomerID,
		update.ExternalSubscriptionID,
		metadata,
	)
	return err
}

func recordPaymentEvent(ctx context.Context, tx *sql.Tx, update SubscriptionUpdate, payload json.RawMessage) error {
	const query = `
INSERT INTO billing_payment_events (
	user_id, provider, event_type, external_id, amount_cents, currency, payload
) VALUES (
	$1,$2,$3,$4,$5,$6,$7
)`
	eventType := string(update.Status)
	_, err := tx.ExecContext(ctx, query,
		update.UserID,
		update.Provider,
		eventType,
		update.ExternalSubscriptionID,
		update.AmountCents,
		update.Currency,
		payload,
	)
	return err
}

func syncEntitlement(ctx context.Context, tx *sql.Tx, update SubscriptionUpdate) error {
	status := "revoked"
	if activeStatuses[update.Status] {
		status = "active"
	}

	const upsert = `
INSERT INTO billing_entitlements (user_id, code, source, status, expires_at, metadata, updated_at)
VALUES ($1,$2,$3,$4,$5,COALESCE($6,'{}'::jsonb), now())
ON CONFLICT (user_id, code)
DO UPDATE SET
	status = EXCLUDED.status,
	expires_at = EXCLUDED.expires_at,
	source = EXCLUDED.source,
	metadata = EXCLUDED.metadata,
	updated_at = EXCLUDED.updated_at;
`
	meta := map[string]any{
		"subscription_status": update.Status,
	}
	if len(update.Metadata) > 0 {
		for k, v := range update.Metadata {
			meta[k] = v
		}
	}
	metaJSON := mapToJSON(meta)

	if _, err := tx.ExecContext(ctx, upsert,
		update.UserID,
		update.EntitlementCode,
		update.Provider,
		status,
		update.EntitlementExpires,
		metaJSON,
	); err != nil {
		return err
	}
	return refreshUserPlan(ctx, tx, update.UserID)
}

func refreshUserPlan(ctx context.Context, tx *sql.Tx, userID uuid.UUID) error {
	const countQuery = `
SELECT COUNT(*) FROM billing_entitlements
WHERE user_id = $1
  AND status = 'active'
  AND (expires_at IS NULL OR expires_at > NOW());
`
	var count int
	if err := tx.QueryRowContext(ctx, countQuery, userID).Scan(&count); err != nil {
		return err
	}
	plan := "free"
	if count > 0 {
		plan = "pro"
	}
	_, err := tx.ExecContext(ctx, `UPDATE users SET plan = $1, updated_at = NOW() WHERE id = $2`, plan, userID)
	return err
}

func mapToJSON(src map[string]any) json.RawMessage {
	if len(src) == 0 {
		return json.RawMessage(`{}`)
	}
	data, err := json.Marshal(src)
	if err != nil {
		return json.RawMessage(`{}`)
	}
	return data
}
