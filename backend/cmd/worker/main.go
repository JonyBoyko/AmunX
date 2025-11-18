package main

import (
	"context"
	"os/signal"
	"sync"
	"syscall"
	"time"

	_ "github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/smartinbox"
	"github.com/amunx/backend/internal/worker/audio"
	smartinboxworker "github.com/amunx/backend/internal/worker/smartinbox"
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

	deps, err := app.Build(ctx, cfg, log)
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

	generator := smartinboxworker.Generator{
		DB:          deps.DB,
		Store:       smartinbox.NewStore(deps.DB),
		Logger:      log.With().Str("processor", "smart_inbox").Logger(),
		SnapshotTTL: smartinbox.DefaultSnapshotTTL,
		Limit:       120,
	}

	processor := audio.Processor{
		DB:      deps.DB,
		Storage: deps.Storage,
		Queue:   deps.Queue,
		Logger:  log.With().Str("processor", "audio").Logger(),
		CDNBase: deps.Config.CDNBaseURL,
	}

	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		if err := generator.Run(ctx); err != nil && err != context.Canceled {
			log.Error().Err(err).Msg("smart inbox generator exited")
		}
	}()

	if err := processor.Run(ctx, deps.Config.WorkerPollInterval); err != nil && err != context.Canceled {
		log.Error().Err(err).Msg("audio processor exited with error")
	}

	cancel()
	wg.Wait()

	log.Info().Msg("worker exiting")
}
