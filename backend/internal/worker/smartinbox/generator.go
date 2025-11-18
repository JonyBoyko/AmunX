package smartinboxworker

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/smartinbox"
)

const (
	defaultGeneratorInterval = 5 * time.Minute
	pruneHorizon             = 24 * time.Hour
)

// Generator periodically materializes Smart Inbox digests for fast reads.
type Generator struct {
	DB          *sql.DB
	Store       *smartinbox.Store
	Logger      zerolog.Logger
	Interval    time.Duration
	SnapshotTTL time.Duration
	Limit       int
}

// Run starts the generator loop until context cancellation.
func (g *Generator) Run(ctx context.Context) error {
	if g.Store == nil {
		g.Store = smartinbox.NewStore(g.DB)
	}
	interval := g.Interval
	if interval <= 0 {
		interval = defaultGeneratorInterval
	}

	// Warm cache immediately before entering the ticker loop.
	if err := g.Generate(ctx); err != nil && !errors.Is(err, context.Canceled) {
		g.Logger.Error().Err(err).Msg("smart inbox warmup failed")
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			if err := g.Generate(ctx); err != nil && !errors.Is(err, context.Canceled) {
				g.Logger.Error().Err(err).Msg("smart inbox generation failed")
			}
		}
	}
}

// Generate executes a single fetch/build/save round.
func (g *Generator) Generate(ctx context.Context) error {
	if g.DB == nil {
		return errors.New("smart inbox generator requires db")
	}
	limit := g.Limit
	if limit <= 0 {
		limit = 120
	}

	rows, err := smartinbox.FetchEpisodeRows(ctx, g.DB, limit)
	if err != nil {
		return err
	}

	now := time.Now().UTC()
	resp := smartinbox.BuildResponse(rows, now)

	ttl := g.SnapshotTTL
	if ttl <= 0 {
		ttl = smartinbox.DefaultSnapshotTTL
	}

	if err := g.Store.Save(ctx, resp, now, ttl, len(rows)); err != nil {
		return err
	}

	// Best-effort cleanup of historical payloads.
	if err := g.Store.Prune(ctx, now.Add(-pruneHorizon)); err != nil {
		g.Logger.Warn().Err(err).Msg("smart inbox prune failed")
	}

	g.Logger.Info().
		Int("episodes", len(rows)).
		Str("generated_at", resp.GeneratedAt).
		Msg("smart inbox snapshot saved")

	return nil
}
