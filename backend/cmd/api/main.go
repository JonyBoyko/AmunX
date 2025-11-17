package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
	apiserver "github.com/amunx/backend/internal/http"
	"github.com/amunx/backend/pkg/logger"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	cfg, err := app.LoadConfig("")
	if err != nil {
		panic(err)
	}

	log := logger.New(cfg.Environment)

	deps, err := app.Build(ctx, cfg, log)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to build application")
	}
	defer func() {
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		if err := deps.Close(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("error during shutdown")
		}
	}()

	server := apiserver.NewServer(cfg, log, deps)

	errCh := make(chan error, 1)
	go func() {
		errCh <- server.Start()
	}()

	select {
	case <-ctx.Done():
		log.Info().Msg("shutdown signal received")
	case err := <-errCh:
		if err != nil {
			log.Error().Err(err).Msg("api server exited with error")
			os.Exit(1)
		}
	}

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("failed to gracefully shutdown server")
	}
}

