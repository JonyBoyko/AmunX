package smartinbox

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"
)

// DefaultSnapshotTTL controls how long cached payloads remain valid.
const DefaultSnapshotTTL = 15 * time.Minute

// ErrNoSnapshot indicates no valid cached payload was found.
var ErrNoSnapshot = errors.New("smart inbox snapshot not found")

// Snapshot represents a cached Smart Inbox payload.
type Snapshot struct {
	ID          int64
	Response    Response
	GeneratedAt time.Time
	ValidUntil  time.Time
	SourceCount int
}

// Store persists Smart Inbox payloads for reuse.
type Store struct {
	DB *sql.DB
}

// NewStore constructs a Smart Inbox store.
func NewStore(db *sql.DB) *Store {
	return &Store{DB: db}
}

// LoadLatest returns the latest valid snapshot if one exists.
func (s *Store) LoadLatest(ctx context.Context, now time.Time) (*Snapshot, error) {
	if s == nil || s.DB == nil {
		return nil, errors.New("smart inbox store requires db")
	}

	const query = `
SELECT id, payload, generated_at, valid_until, source_count
  FROM smart_inbox_snapshots
 WHERE valid_until > $1
 ORDER BY valid_until DESC, generated_at DESC
 LIMIT 1`

	row := s.DB.QueryRowContext(ctx, query, now)

	var (
		id          int64
		payload     []byte
		generatedAt time.Time
		validUntil  time.Time
		sourceCount int
	)

	if err := row.Scan(&id, &payload, &generatedAt, &validUntil, &sourceCount); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNoSnapshot
		}
		return nil, err
	}

	var resp Response
	if err := json.Unmarshal(payload, &resp); err != nil {
		return nil, err
	}

	return &Snapshot{
		ID:          id,
		Response:    resp,
		GeneratedAt: generatedAt,
		ValidUntil:  validUntil,
		SourceCount: sourceCount,
	}, nil
}

// Save persists a snapshot with the provided TTL.
func (s *Store) Save(ctx context.Context, resp Response, generatedAt time.Time, ttl time.Duration, sourceCount int) error {
	if s == nil || s.DB == nil {
		return errors.New("smart inbox store requires db")
	}
	if ttl <= 0 {
		ttl = DefaultSnapshotTTL
	}
	if resp.GeneratedAt == "" {
		resp.GeneratedAt = generatedAt.Format(time.RFC3339)
	}

	payload, err := json.Marshal(resp)
	if err != nil {
		return err
	}

	const query = `
INSERT INTO smart_inbox_snapshots (payload, generated_at, valid_until, source_count)
VALUES ($1, $2, $3, $4)
`
	_, err = s.DB.ExecContext(ctx, query, payload, generatedAt, generatedAt.Add(ttl), sourceCount)
	return err
}

// Prune removes stale snapshots older than the provided threshold.
func (s *Store) Prune(ctx context.Context, olderThan time.Time) error {
	if s == nil || s.DB == nil {
		return errors.New("smart inbox store requires db")
	}
	const query = `DELETE FROM smart_inbox_snapshots WHERE generated_at < $1`
	_, err := s.DB.ExecContext(ctx, query, olderThan)
	return err
}
