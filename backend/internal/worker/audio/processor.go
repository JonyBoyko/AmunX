package audio

import (
	"bytes"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

const (
	consumerGroup = "process_audio"
)

type Processor struct {
	DB      *sql.DB
	Storage storage.Client
	Queue   queue.Stream
	Logger  zerolog.Logger
	CDNBase string
}

func (p *Processor) Run(ctx context.Context, pollInterval time.Duration) error {
	consumerName := "proc-" + uuid.NewString()[:8]
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		if err := p.claimAndProcess(ctx, consumerName); err != nil {
			p.Logger.Error().Err(err).Msg("error processing audio job")
		}

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
		}
	}
}

func (p *Processor) claimAndProcess(ctx context.Context, consumer string) error {
	messages, err := p.Queue.Claim(ctx, queue.TopicProcessAudio, consumerGroup, consumer, 5)
	if err != nil {
		return err
	}

	if len(messages) == 0 {
		return nil
	}

	for _, msg := range messages {
		episodeID, ok := msg.Values["episode_id"].(string)
		if !ok || episodeID == "" {
			p.Logger.Warn().Interface("message", msg).Msg("missing episode_id in job")
			_ = p.Queue.Ack(ctx, queue.TopicProcessAudio, consumerGroup, msg.ID)
			continue
		}

		if err := p.handleMessage(ctx, episodeID); err != nil {
			p.Logger.Error().Err(err).Str("episode_id", episodeID).Msg("failed to process episode")
			continue
		}

		if err := p.Queue.Ack(ctx, queue.TopicProcessAudio, consumerGroup, msg.ID); err != nil {
			p.Logger.Error().Err(err).Str("episode_id", episodeID).Msg("failed to ack message")
		}
	}

	return nil
}

func (p *Processor) handleMessage(ctx context.Context, episodeID string) error {
	const selectEpisode = `
SELECT id, storage_key
FROM episodes
WHERE id = $1 AND status = 'pending_public'
`

	var (
		id         uuid.UUID
		storageKey sql.NullString
	)

	if err := p.DB.QueryRowContext(ctx, selectEpisode, episodeID).Scan(&id, &storageKey); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil
		}
		return err
	}

	processedKey := fmt.Sprintf("episodes/%s/processed.opus", id.String())
	processedURL := processedKey
	if p.CDNBase != "" {
		processedURL = fmt.Sprintf("%s/%s", strings.TrimSuffix(p.CDNBase, "/"), processedKey)
	}

	if err := p.uploadPlaceholder(ctx, processedKey); err != nil {
		return err
	}

	const updateEpisode = `
UPDATE episodes
SET status = 'public',
    audio_url = $2,
    storage_key = $3,
    size_bytes = $4,
    status_changed_at = now(),
    updated_at = now(),
    published_at = COALESCE(published_at, now())
WHERE id = $1
`

	if _, err := p.DB.ExecContext(ctx, updateEpisode, id, processedURL, processedKey, 0); err != nil {
		return err
	}

	return nil
}

func (p *Processor) uploadPlaceholder(ctx context.Context, key string) error {
	reader := bytes.NewReader([]byte{})
	_, err := p.Storage.PutObject(ctx, key, reader, map[string]string{"processed": "true"})
	return err
}
