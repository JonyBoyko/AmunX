package app

import (
	"time"

	"github.com/kelseyhightower/envconfig"
)

// Config holds all runtime configuration sourced from the environment.
type Config struct {
	Environment string `envconfig:"ENVIRONMENT" default:"development"`

	HTTPHost         string        `envconfig:"HTTP_HOST" default:"0.0.0.0"`
	HTTPPort         int           `envconfig:"HTTP_PORT" default:"8080"`
	HTTPReadTimeout  time.Duration `envconfig:"HTTP_READ_TIMEOUT" default:"15s"`
	HTTPWriteTimeout time.Duration `envconfig:"HTTP_WRITE_TIMEOUT" default:"30s"`
	HTTPIdleTimeout  time.Duration `envconfig:"HTTP_IDLE_TIMEOUT" default:"60s"`
	RateLimitWindow  time.Duration `envconfig:"RATE_LIMIT_WINDOW" default:"1m"`
	RateLimitMax     int           `envconfig:"RATE_LIMIT_MAX" default:"120"`

	DatabaseURL string `envconfig:"DATABASE_URL" default:"postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable"`

	RedisAddress  string        `envconfig:"REDIS_ADDRESS" default:"localhost:6379"`
	RedisPassword string        `envconfig:"REDIS_PASSWORD" default:""`
	RedisDB       int           `envconfig:"REDIS_DB" default:"0"`
	RedisTimeout  time.Duration `envconfig:"REDIS_TIMEOUT" default:"5s"`

	StorageEndpoint string `envconfig:"STORAGE_ENDPOINT" default:""`
	StorageRegion   string `envconfig:"STORAGE_REGION" default:"auto"`
	StorageBucket   string `envconfig:"STORAGE_BUCKET" default:"amunx"`
	StorageAccess   string `envconfig:"STORAGE_ACCESS_KEY" default:""`
	StorageSecret   string `envconfig:"STORAGE_SECRET_KEY" default:""`

	CDNBaseURL string `envconfig:"CDN_BASE_URL" default:""`
	LocalMediaPath     string        `envconfig:"LOCAL_MEDIA_PATH" default:"./media"`
	WorkerPollInterval time.Duration `envconfig:"WORKER_POLL_INTERVAL" default:"2s"`

	JWTAccessSecret      string        `envconfig:"JWT_ACCESS_SECRET" default:""`
	JWTRefreshSecret     string        `envconfig:"JWT_REFRESH_SECRET" default:""`
	JWTAccessTTL         time.Duration `envconfig:"JWT_ACCESS_TTL" default:"15m"`
	JWTRefreshTTL        time.Duration `envconfig:"JWT_REFRESH_TTL" default:"720h"`
	MagicLinkTokenSecret string        `envconfig:"MAGIC_LINK_TOKEN_SECRET" default:""`
	MagicLinkTTL         time.Duration `envconfig:"MAGIC_LINK_TTL" default:"15m"`

	PublicByDefault bool    `envconfig:"PUBLIC_BY_DEFAULT" default:"true"`
	UndoSeconds     int     `envconfig:"UNDO_SECONDS" default:"10"`
	OpusKbps        int     `envconfig:"OPUS_KBPS" default:"24"`
	LiveShareMax    float64 `envconfig:"LIVE_SHARE_PERCENT" default:"5"`
	STTProOnly      bool    `envconfig:"STT_PRO_ONLY" default:"true"`

	FeatureFreeKeywords  bool `envconfig:"FEATURE_FREE_KEYWORDS" default:"true"`
	FeatureLiveRecording bool `envconfig:"FEATURE_LIVE_RECORDING" default:"true"`
	FeatureLiveMaskBeta  bool `envconfig:"FEATURE_LIVE_MASK_BETA" default:"false"`
	FeatureProSTT        bool `envconfig:"FEATURE_PRO_STT" default:"true"`
	FeaturePublicDefault bool `envconfig:"FEATURE_PUBLIC_DEFAULT" default:"true"`
}

// LoadConfig loads configuration using the provided environment variable prefix.
func LoadConfig(prefix string) (Config, error) {
	var cfg Config
	if err := envconfig.Process(prefix, &cfg); err != nil {
		return Config{}, err
	}
	return cfg, nil
}
