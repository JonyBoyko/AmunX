package app

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/auth"
	"github.com/amunx/backend/internal/email"
	"github.com/amunx/backend/internal/integrations/monopay"
	"github.com/amunx/backend/internal/push"
	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

// App wires together long-lived dependencies for the service.
type App struct {
	Config Config

	DB          *sql.DB
	Redis       *redis.Client
	MagicLinks  *auth.MagicLinkSigner
	JWT         *auth.JWTManager
	Storage     storage.Client
	Queue       queue.Stream
	Email       email.Sender
	Push        push.Sender
	MonoPay     *monopay.Client
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
func Build(ctx context.Context, cfg Config, log zerolog.Logger) (*App, error) {
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

	magicSigner, err := auth.NewMagicLinkSigner(cfg.MagicLinkTokenSecret, cfg.MagicLinkTTL)
	if err != nil {
		return nil, fmt.Errorf("magic link signer: %w", err)
	}

	if cfg.JWTAccessSecret == "" || cfg.JWTRefreshSecret == "" {
		return nil, errors.New("jwt secrets must be provided")
	}
	jwtManager := auth.NewJWTManager(cfg.JWTAccessSecret, cfg.JWTRefreshSecret, cfg.JWTAccessTTL, cfg.JWTRefreshTTL)

	store, err := storage.NewS3Client(storage.S3Config{
		Endpoint:  cfg.StorageEndpoint,
		Region:    cfg.StorageRegion,
		Bucket:    cfg.StorageBucket,
		AccessKey: cfg.StorageAccess,
		SecretKey: cfg.StorageSecret,
	})
	if err != nil {
		if !errors.Is(err, storage.ErrIncompleteConfig) {
			return nil, fmt.Errorf("storage client: %w", err)
		}
		if cfg.Environment == "development" {
			store = storage.NewNoopClient()
		} else {
			return nil, fmt.Errorf("storage client: %w", err)
		}
	}

	queueClient := queue.NewRedisStream(redisClient)

	emailSender := email.NewSender(email.Options{
		Host:     cfg.SMTPHost,
		Port:     cfg.SMTPPort,
		Username: cfg.SMTPUsername,
		Password: cfg.SMTPPassword,
		From:     cfg.EmailFrom,
	}, log)

	pushSender := push.NewSender(push.Config{
		ServerKey: cfg.FCMServerKey,
		Endpoint:  cfg.FCMEndpoint,
	}, log)

	var monoClient *monopay.Client
	if cfg.MonoPayAPIKey != "" && cfg.MonoPayMerchantID != "" {
		monoClient = monopay.NewClient(monopay.Config{
			BaseURL:  cfg.MonoPayAPIBaseURL,
			APIToken: cfg.MonoPayAPIKey,
			Merchant: cfg.MonoPayMerchantID,
			Logger:   log,
		})
	}

	return &App{
		Config:     cfg,
		DB:         db,
		Redis:      redisClient,
		MagicLinks: magicSigner,
		JWT:        jwtManager,
		Storage:    store,
		Queue:      queueClient,
		Email:      emailSender,
		Push:       pushSender,
		MonoPay:    monoClient,
	}, nil
}
