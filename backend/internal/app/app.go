package app

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/redis/go-redis/v9"
)

// App wires together long-lived dependencies for the service.
type App struct {
	Config Config

	DB          *sql.DB
	Redis       *redis.Client
	ShutdownFns []func(context.Context) error
}

// Close releases resources gracefully.
func (a *App) Close(ctx context.Context) error {
	var firstErr error

	if a.DB != nil {
		if err := a.DB.Close(); err != nil && firstErr == nil {
			firstErr = err
		}
	}

	if a.Redis != nil {
		if err := a.Redis.Close(); err != nil && firstErr == nil {
			firstErr = err
		}
	}

	for _, fn := range a.ShutdownFns {
		if err := fn(ctx); err != nil && firstErr == nil {
			firstErr = err
		}
	}

	return firstErr
}

// Build constructs the App with connections according to the supplied config.
func Build(ctx context.Context, cfg Config) (*App, error) {
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("connect database: %w", err)
	}

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("ping database: %w", err)
	}

	redisClient := redis.NewClient(&redis.Options{
		Addr:         cfg.RedisAddress,
		Password:     cfg.RedisPassword,
		DB:           cfg.RedisDB,
		DialTimeout:  cfg.RedisTimeout,
		ReadTimeout:  cfg.RedisTimeout,
		WriteTimeout: cfg.RedisTimeout,
	})

	if err := redisClient.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("ping redis: %w", err)
	}

	return &App{
		Config: cfg,
		DB:     db,
		Redis:  redisClient,
	}, nil
}

