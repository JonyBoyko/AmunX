package push

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/rs/zerolog"
)

type firebaseSender struct {
	client    *http.Client
	serverKey string
	endpoint  string
	logger    zerolog.Logger
}

func newFirebaseSender(serverKey, endpoint string, logger zerolog.Logger) Sender {
	return &firebaseSender{
		client: &http.Client{
			Timeout: 5 * time.Second,
		},
		serverKey: serverKey,
		endpoint:  endpoint,
		logger:    logger,
	}
}

func (f *firebaseSender) Send(ctx context.Context, msg Message) error {
	payload := map[string]any{
		"to": msg.Token,
		"notification": map[string]string{
			"title": msg.Title,
			"body":  msg.Body,
		},
		"data": msg.Data,
		"android": map[string]any{
			"priority": "high",
		},
		"apns": map[string]any{
			"headers": map[string]string{
				"apns-priority": "10",
			},
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, f.endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Authorization", "key="+f.serverKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := f.client.Do(req)
	if err != nil {
		return fmt.Errorf("send push: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		respBody, _ := io.ReadAll(resp.Body)
		f.logger.Error().
			Str("token", msg.Token).
			Int("status", resp.StatusCode).
			Msg("fcm send failed")
		return fmt.Errorf("fcm send failed: %s", string(respBody))
	}
	return nil
}
