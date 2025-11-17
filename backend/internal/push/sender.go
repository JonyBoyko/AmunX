package push

import (
	"context"

	"github.com/rs/zerolog"
)

// Message represents a single push notification payload.
type Message struct {
	Token string
	Title string
	Body  string
	Data  map[string]string
}

// Sender dispatches push notifications to devices.
type Sender interface {
	Send(ctx context.Context, msg Message) error
}

// Config describes the push transport configuration.
type Config struct {
	ServerKey string
	Endpoint  string
}

// NewSender builds a push sender for the provided configuration.
func NewSender(cfg Config, logger zerolog.Logger) Sender {
	if cfg.ServerKey == "" {
		logger.Warn().Msg("FCM server key not configured, push notifications disabled")
		return &noopSender{logger: logger}
	}
	endpoint := cfg.Endpoint
	if endpoint == "" {
		endpoint = "https://fcm.googleapis.com/fcm/send"
	}
	return newFirebaseSender(cfg.ServerKey, endpoint, logger)
}

type noopSender struct {
	logger zerolog.Logger
}

func (n *noopSender) Send(ctx context.Context, msg Message) error {
	n.logger.Debug().
		Str("token", msg.Token).
		Str("title", msg.Title).
		Msg("push noop sender called")
	return nil
}
