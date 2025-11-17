package http

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/billing"
	"github.com/amunx/backend/internal/httpctx"
	"github.com/amunx/backend/internal/integrations/monopay"
)

func registerBillingRoutes(r chi.Router, deps *app.App) {
	r.Get("/billing/products", handleBillingProducts(deps))
	r.Get("/billing/subscription", handleBillingSubscription(deps))
	r.Post("/billing/portal", handleBillingPortal(deps))
	r.Post("/billing/monopay/checkout", handleMonoPayCheckout(deps))
}

func registerBillingWebhookRoutes(r chi.Router, deps *app.App) {
	r.Post("/billing/webhooks/stripe", handleStripeWebhook(deps))
	r.Post("/billing/webhooks/revenuecat", handleRevenueCatWebhook(deps))
	r.Post("/billing/webhooks/monopay", handleMonoPayWebhook(deps))
}

func handleBillingProducts(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		_, ok := httpctx.UserFromContext(r.Context())
		if !ok {
			WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
			return
		}
		svc := billing.NewService(deps.DB)
		products, err := svc.ListActiveProducts(r.Context())
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "billing_products_failed", err.Error())
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{
			"products": products,
		})
	}
}

func handleBillingSubscription(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, ok := httpctx.UserFromContext(r.Context())
		if !ok {
			WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
			return
		}
		svc := billing.NewService(deps.DB)
		snapshot, err := svc.CurrentSubscription(r.Context(), user.ID)
		if err != nil && err != billing.ErrSubscriptionNotFound {
			WriteError(w, http.StatusInternalServerError, "billing_subscription_failed", err.Error())
			return
		}
		response := map[string]any{
			"plan":         user.Plan,
			"subscription": snapshot,
		}
		WriteJSON(w, http.StatusOK, response)
	}
}

func handleBillingPortal(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, ok := httpctx.UserFromContext(r.Context())
		if !ok {
			WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
			return
		}
		response := map[string]any{
			"user_id":                 user.ID.String(),
			"stripe_customer_portal":  deps.Config.StripePortalURL,
			"revenuecat_app_user_id":  user.ID.String(),
			"monopay_checkout_notice": "MonoPay checkout handled client-side",
		}
		WriteJSON(w, http.StatusOK, response)
	}
}

func handleMonoPayCheckout(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user, ok := httpctx.UserFromContext(r.Context())
		if !ok {
			WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
			return
		}
		if deps.MonoPay == nil {
			WriteError(w, http.StatusServiceUnavailable, "monopay_disabled", "MonoPay integration not configured")
			return
		}
		if deps.Config.MonoPayWebhookURL == "" {
			WriteError(w, http.StatusServiceUnavailable, "monopay_webhook_missing", "MONOPAY_WEBHOOK_URL not configured")
			return
		}

		var req struct {
			ProductCode string `json:"product_code"`
			SuccessURL  string `json:"success_url"`
		}
		if err := decodeJSON(r, &req); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		if strings.TrimSpace(req.ProductCode) == "" {
			WriteError(w, http.StatusBadRequest, "invalid_request", "product_code is required")
			return
		}

		svc := billing.NewService(deps.DB)
		product, err := svc.GetProductByCode(r.Context(), req.ProductCode)
		if err != nil {
			if err == billing.ErrProductNotFound {
				WriteError(w, http.StatusNotFound, "product_not_found", "billing product not found")
				return
			}
			WriteError(w, http.StatusInternalServerError, "product_lookup_failed", err.Error())
			return
		}
		if product.Provider != billing.ProviderMonoPay {
			WriteError(w, http.StatusBadRequest, "invalid_provider", "product is not a MonoPay plan")
			return
		}

		redirect := strings.TrimSpace(req.SuccessURL)
		if redirect == "" {
			redirect = deps.Config.MonoPayReturnURL
		}

		reference := fmt.Sprintf("mono-%s-%d", user.ID.String(), time.Now().Unix())
		customerData := map[string]string{
			"user_id":      user.ID.String(),
			"product_code": product.Code,
		}

		invoice, err := deps.MonoPay.CreateInvoice(r.Context(), monopay.InvoiceRequest{
			AmountCents:  product.AmountCents,
			Currency:     product.Currency,
			Reference:    reference,
			Destination:  firstNonEmpty(product.Description, product.Name, "Moweton Pro"),
			RedirectURL:  redirect,
			WebhookURL:   deps.Config.MonoPayWebhookURL,
			CustomerData: customerData,
			Validity:     time.Hour,
		})
		if err != nil {
			WriteError(w, http.StatusBadGateway, "monopay_invoice_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"invoice_id":   invoice.InvoiceID,
			"checkout_url": invoice.PageURL,
			"reference":    reference,
			"amount_cents": product.AmountCents,
			"currency":     product.Currency,
		})
	}
}

func handleRevenueCatWebhook(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if deps.Config.RevenueCatWebhookSecret != "" {
			if sig := r.Header.Get("X-Signature"); sig != deps.Config.RevenueCatWebhookSecret {
				WriteError(w, http.StatusUnauthorized, "invalid_signature", "revenuecat webhook signature mismatch")
				return
			}
		}
		body, err := io.ReadAll(r.Body)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		var payload revenueCatPayload
		if err := json.NewDecoder(bytes.NewReader(body)).Decode(&payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_payload", err.Error())
			return
		}
		userID, err := uuid.Parse(payload.Event.AppUserID)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_user", "app_user_id must be a UUID")
			return
		}
		status := mapRevenueCatStatus(payload.Event.Type)
		exp := payload.Event.ExpirationAt()

		update := billing.SubscriptionUpdate{
			UserID:                 userID,
			Provider:               billing.ProviderRevenueCat,
			ProductCode:            safeString(payload.Event.ProductID, "revenuecat_unknown"),
			ProductName:            payload.Event.ProductID,
			ProductDescription:     fmt.Sprintf("RevenueCat %s", payload.Event.EntitlementID),
			ExternalProductID:      payload.Event.ProductID,
			ExternalSubscriptionID: safeString(payload.Event.OriginalTransactionID, payload.Event.AppUserID),
			Currency:               "USD",
			AmountCents:            0,
			Interval:               mapRevenueCatInterval(payload.Event.PeriodType),
			Status:                 status,
			CurrentPeriodEnd:       exp,
			EntitlementCode:        safeString(payload.Event.EntitlementID, "pro"),
			EntitlementExpires:     exp,
			Metadata: map[string]any{
				"environment": payload.Event.Environment,
				"event_type":  payload.Event.Type,
			},
			RawEvent: body,
		}
		svc := billing.NewService(deps.DB)
		if err := svc.ApplySubscriptionUpdate(r.Context(), update); err != nil {
			WriteError(w, http.StatusInternalServerError, "revenuecat_apply_failed", err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleStripeWebhook(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		if deps.Config.StripeWebhookSecret != "" {
			header := r.Header.Get("Stripe-Signature")
			if !verifyStripeSignature(body, header, deps.Config.StripeWebhookSecret) {
				WriteError(w, http.StatusUnauthorized, "invalid_signature", "stripe signature mismatch")
				return
			}
		}

		var event stripeEvent
		if err := json.NewDecoder(bytes.NewReader(body)).Decode(&event); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_payload", err.Error())
			return
		}
		if !strings.HasPrefix(event.Type, "customer.subscription.") {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		sub := event.Data.Object
		userIDStr := sub.Metadata["user_id"]
		if userIDStr == "" {
			WriteError(w, http.StatusBadRequest, "missing_metadata", "metadata.user_id required")
			return
		}
		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_user", "metadata.user_id must be UUID")
			return
		}
		productCode := sub.Metadata["product_code"]
		if productCode == "" && len(sub.Items.Data) > 0 {
			productCode = sub.Items.Data[0].Price.ID
		}
		interval := "month"
		amount := 0
		currency := strings.ToUpper(sub.Currency)
		if len(sub.Items.Data) > 0 {
			item := sub.Items.Data[0]
			if item.Price.Recurring.Interval != "" {
				interval = item.Price.Recurring.Interval
			}
			if item.Price.UnitAmount > 0 {
				amount = item.Price.UnitAmount
			}
			if item.Price.Currency != "" {
				currency = strings.ToUpper(item.Price.Currency)
			}
		}
		currentEnd := toTimePointer(sub.CurrentPeriodEnd)
		cancelAt := toTimePointer(sub.CancelAt)
		canceledAt := toTimePointer(sub.CanceledAt)

		meta := map[string]any{
			"stripe_status": sub.Status,
		}
		for k, v := range sub.Metadata {
			meta[k] = v
		}

		update := billing.SubscriptionUpdate{
			UserID:                 userID,
			Provider:               billing.ProviderStripe,
			ProductCode:            productCode,
			ProductName:            sub.Metadata["product_name"],
			ProductDescription:     sub.Metadata["description"],
			ExternalProductID:      productCode,
			ExternalSubscriptionID: sub.ID,
			ExternalCustomerID:     sub.Customer,
			Currency:               currency,
			AmountCents:            amount,
			Interval:               interval,
			Status:                 mapStripeStatus(sub.Status),
			CurrentPeriodEnd:       currentEnd,
			CancelAt:               cancelAt,
			CanceledAt:             canceledAt,
			EntitlementCode:        safeString(sub.Metadata["entitlement"], "pro"),
			EntitlementExpires:     currentEnd,
			Metadata:               meta,
			RawEvent:               body,
		}
		svc := billing.NewService(deps.DB)
		if err := svc.ApplySubscriptionUpdate(r.Context(), update); err != nil {
			WriteError(w, http.StatusInternalServerError, "stripe_apply_failed", err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleMonoPayWebhook(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		header := r.Header.Get("X-Signature")
		if deps.Config.MonoPayWebhookSecret != "" {
			if !verifyHMACSignature(body, header, deps.Config.MonoPayWebhookSecret) {
				WriteError(w, http.StatusUnauthorized, "invalid_signature", "monopay signature mismatch")
				return
			}
		}
		var payload monoPayPayload
		if err := json.NewDecoder(bytes.NewReader(body)).Decode(&payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_payload", err.Error())
			return
		}
		customerData := parseMonoPayCustomerData(payload.CustomerData)
		userID, err := resolveMonoPayUser(payload, customerData)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_user", err.Error())
			return
		}
		status := mapMonoPayStatus(payload.Status)
		exp := time.Now().AddDate(0, 1, 0)
		productCode := safeString(payload.ProductCode, customerData["product_code"])
		if productCode == "" {
			productCode = "monopay_plan"
		}
		productName := firstNonEmpty(payload.ProductName, productCode)
		meta := map[string]any{
			"invoice_id": payload.InvoiceID,
			"order_id":   payload.OrderID,
			"status":     payload.Status,
		}
		for k, v := range customerData {
			meta[k] = v
		}

		update := billing.SubscriptionUpdate{
			UserID:                 userID,
			Provider:               billing.ProviderMonoPay,
			ProductCode:            productCode,
			ProductName:            productName,
			ProductDescription:     firstNonEmpty(payload.Details, productName),
			ExternalProductID:      productCode,
			ExternalSubscriptionID: payload.InvoiceID,
			ExternalCustomerID:     payload.CustomerID,
			Currency:               strings.ToUpper(payload.Currency),
			AmountCents:            payload.Amount,
			Interval:               "month",
			Status:                 status,
			CurrentPeriodEnd:       &exp,
			EntitlementCode:        safeString(payload.EntitlementCode, productCode),
			EntitlementExpires:     &exp,
			Metadata:               meta,
			RawEvent:               body,
		}
		svc := billing.NewService(deps.DB)
		if err := svc.ApplySubscriptionUpdate(r.Context(), update); err != nil {
			WriteError(w, http.StatusInternalServerError, "monopay_apply_failed", err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func verifyStripeSignature(body []byte, header, secret string) bool {
	if header == "" || secret == "" {
		return false
	}
	var ts, sig string
	parts := strings.Split(header, ",")
	for _, part := range parts {
		pair := strings.SplitN(part, "=", 2)
		if len(pair) != 2 {
			continue
		}
		switch pair[0] {
		case "t":
			ts = pair[1]
		case "v1":
			sig = pair[1]
		}
	}
	if ts == "" || sig == "" {
		return false
	}
	signed := ts + "." + string(body)
	expected := computeHexHMAC(secret, signed)
	return hmac.Equal([]byte(sig), []byte(expected))
}

func verifyHMACSignature(body []byte, header, secret string) bool {
	if header == "" || secret == "" {
		return false
	}
	expected := computeHexHMAC(secret, string(body))
	return hmac.Equal([]byte(strings.ToLower(header)), []byte(strings.ToLower(expected)))
}

func computeHexHMAC(secret, payload string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(payload))
	return hex.EncodeToString(mac.Sum(nil))
}

func safeString(value, fallback string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return fallback
	}
	return value
}

func toTimePointer(unix int64) *time.Time {
	if unix == 0 {
		return nil
	}
	t := time.Unix(unix, 0)
	return &t
}

func mapRevenueCatStatus(eventType string) billing.SubscriptionStatus {
	switch strings.ToUpper(eventType) {
	case "INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE":
		return billing.StatusActive
	case "EXPIRATION":
		return billing.StatusExpired
	case "CANCELLATION":
		return billing.StatusCanceled
	default:
		return billing.StatusPastDue
	}
}

func mapRevenueCatInterval(periodType string) string {
	switch strings.ToLower(periodType) {
	case "annual":
		return "year"
	default:
		return "month"
	}
}

func mapStripeStatus(status string) billing.SubscriptionStatus {
	switch strings.ToLower(status) {
	case "trialing":
		return billing.StatusTrialing
	case "active":
		return billing.StatusActive
	case "past_due":
		return billing.StatusPastDue
	case "canceled":
		return billing.StatusCanceled
	default:
		return billing.StatusExpired
	}
}

func mapMonoPayStatus(status string) billing.SubscriptionStatus {
	switch strings.ToLower(status) {
	case "pending":
		return billing.StatusPastDue
	case "failed", "expired":
		return billing.StatusExpired
	case "canceled":
		return billing.StatusCanceled
	default:
		return billing.StatusActive
	}
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func parseMonoPayCustomerData(raw string) map[string]string {
	result := make(map[string]string)
	if strings.TrimSpace(raw) == "" {
		return result
	}
	var payload map[string]any
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		return result
	}
	for k, v := range payload {
		result[k] = fmt.Sprintf("%v", v)
	}
	return result
}

func resolveMonoPayUser(payload monoPayPayload, meta map[string]string) (uuid.UUID, error) {
	if payload.UserID != "" {
		return uuid.Parse(payload.UserID)
	}
	if userID := meta["user_id"]; userID != "" {
		return uuid.Parse(userID)
	}
	if payload.OrderID != "" {
		if candidate, err := uuid.Parse(payload.OrderID); err == nil {
			return candidate, nil
		}
		if candidate, err := parseUserFromReference(payload.OrderID); err == nil {
			return candidate, nil
		}
	}
	return uuid.Nil, errors.New("user_id not provided in webhook payload")
}

func parseUserFromReference(reference string) (uuid.UUID, error) {
	trimmed := strings.TrimPrefix(reference, "mono-")
	parts := strings.Split(trimmed, "-")
	if len(parts) < 5 {
		return uuid.Nil, errors.New("reference format invalid")
	}
	candidate := strings.Join(parts[:len(parts)-1], "-")
	return uuid.Parse(candidate)
}

type revenueCatEvent struct {
	Type                  string `json:"type"`
	AppUserID             string `json:"app_user_id"`
	ProductID             string `json:"product_id"`
	EntitlementID         string `json:"entitlement_id"`
	PeriodType            string `json:"period_type"`
	OriginalTransactionID string `json:"original_transaction_id"`
	Environment           string `json:"environment"`
	ExpiresAtMilliseconds *int64 `json:"expiration_at_ms"`
}

func (e revenueCatEvent) ExpirationAt() *time.Time {
	if e.ExpiresAtMilliseconds == nil || *e.ExpiresAtMilliseconds == 0 {
		return nil
	}
	ms := *e.ExpiresAtMilliseconds
	t := time.UnixMilli(ms)
	return &t
}

type revenueCatPayload struct {
	Event revenueCatEvent `json:"event"`
}

type stripeEvent struct {
	Type string `json:"type"`
	Data struct {
		Object stripeSubscription `json:"object"`
	} `json:"data"`
}

type stripeSubscription struct {
	ID               string                        `json:"id"`
	Customer         string                        `json:"customer"`
	Status           string                        `json:"status"`
	CurrentPeriodEnd int64                         `json:"current_period_end"`
	CancelAt         int64                         `json:"cancel_at"`
	CanceledAt       int64                         `json:"canceled_at"`
	Currency         string                        `json:"currency"`
	Metadata         map[string]string             `json:"metadata"`
	Items            stripeSubscriptionItemWrapper `json:"items"`
}

type stripeSubscriptionItemWrapper struct {
	Data []stripeSubscriptionItem `json:"data"`
}

type stripeSubscriptionItem struct {
	Price stripePrice `json:"price"`
}

type stripePrice struct {
	ID         string          `json:"id"`
	Currency   string          `json:"currency"`
	UnitAmount int             `json:"unit_amount"`
	Recurring  stripeRecurring `json:"recurring"`
}

type stripeRecurring struct {
	Interval string `json:"interval"`
}

type monoPayPayload struct {
	InvoiceID       string `json:"invoice_id"`
	OrderID         string `json:"order_id"`
	UserID          string `json:"user_id"`
	ProductCode     string `json:"product_code"`
	ProductName     string `json:"product_name"`
	EntitlementCode string `json:"entitlement_code"`
	CustomerID      string `json:"customer_id"`
	Status          string `json:"status"`
	Amount          int    `json:"amount"`
	Currency        string `json:"currency"`
	Details         string `json:"details"`
	CustomerData    string `json:"customer_data"`
}
