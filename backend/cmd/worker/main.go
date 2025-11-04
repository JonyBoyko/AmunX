package main

import (
	"context"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/pkg/logger"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	cfg, err := app.LoadConfig("")
	if err != nil {
		panic(err)
	}

	log := logger.New(cfg.Environment).With().Str("component", "worker").Logger()

	deps, err := app.Build(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to build worker dependencies")
	}
	defer func() {
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		if err := deps.Close(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("worker shutdown error")
		}
	}()

	log.Info().Msg("worker started")

	<-ctx.Done()

	log.Info().Msg("worker exiting")
}

