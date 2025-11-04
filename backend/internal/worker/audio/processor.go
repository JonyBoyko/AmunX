package audio

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

const (
	consumerGroup = "process_audio"
	maxAttempts   = 3
)

type Processor struct {
	DB        *sql.DB
	Storage   storage.Client
	Queue     queue.Stream
	Logger    zerolog.Logger
	CDNBase   string
	MediaPath string
}

func (p *Processor) Run(ctx context.Context, pollInterval time.Duration) error {
	if p.MediaPath == "" {
		p.MediaPath = os.TempDir()
	}
	if err := os.MkdirAll(p.MediaPath, 0o755); err != nil {
		return err
	}

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
			p.Logger.Error().Err(err).Msg("processor loop error")
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
		attempt := parseAttempt(msg.Values["attempt"])

		if err := p.handleMessage(ctx, episodeID); err != nil {
			p.Logger.Error().Err(err).Str("episode_id", episodeID).Int("attempt", attempt).Msg("processing failed")

			if attempt+1 >= maxAttempts {
				if markErr := p.markEpisodeFailed(ctx, episodeID, err); markErr != nil {
					p.Logger.Error().Err(markErr).Str("episode_id", episodeID).Msg("failed to mark episode failure")
				}
			} else {
				requeueErr := p.Queue.Enqueue(ctx, queue.TopicProcessAudio, map[string]any{
					"episode_id": episodeID,
					"attempt":    attempt + 1,
				})
				if requeueErr != nil {
					p.Logger.Error().Err(requeueErr).Str("episode_id", episodeID).Msg("failed to requeue job")
				}
			}

			_ = p.Queue.Ack(ctx, queue.TopicProcessAudio, consumerGroup, msg.ID)
			continue
		}

		if err := p.Queue.Ack(ctx, queue.TopicProcessAudio, consumerGroup, msg.ID); err != nil {
			p.Logger.Error().Err(err).Str("episode_id", episodeID).Msg("failed to ack message")
		}
	}

	return nil
}

func parseAttempt(value any) int {
	switch v := value.(type) {
	case int64:
		return int(v)
	case int:
		return v
	case string:
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return 0
}

func (p *Processor) handleMessage(ctx context.Context, episodeID string) error {
	const selectEpisode = `
SELECT id, storage_key, mask
FROM episodes
WHERE id = $1 AND status = 'pending_public'
`

	var (
		id         uuid.UUID
		storageKey sql.NullString
		mask       string
	)

	if err := p.DB.QueryRowContext(ctx, selectEpisode, episodeID).Scan(&id, &storageKey, &mask); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil
		}
		return err
	}

	if !storageKey.Valid || storageKey.String == "" {
		return errors.New("missing storage key")
	}

	tempDir, err := os.MkdirTemp(p.MediaPath, "episode-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	originalPath := filepath.Join(tempDir, "original")
	if err := p.downloadOriginal(ctx, storageKey.String, originalPath); err != nil {
		return err
	}

	processedPath := filepath.Join(tempDir, "processed.opus")
	if err := p.processWithFFmpeg(ctx, originalPath, processedPath, mask); err != nil {
		return err
	}

	waveform, duration, sizeBytes, err := p.extractMetadata(ctx, processedPath)
	if err != nil {
		return err
	}

	processedKey := fmt.Sprintf("episodes/%s/processed.opus", id.String())
	processedURL := processedKey
	if p.CDNBase != "" {
		processedURL = fmt.Sprintf("%s/%s", strings.TrimSuffix(p.CDNBase, "/"), processedKey)
	}

	if err := p.uploadProcessed(ctx, processedKey, processedPath); err != nil {
		return err
	}

	const updateEpisode = `
UPDATE episodes
SET status = 'public',
    audio_url = $2,
    storage_key = $3,
    size_bytes = $4,
    waveform_json = $5,
    duration_sec = $6,
    status_changed_at = now(),
    updated_at = now(),
    published_at = COALESCE(published_at, now())
WHERE id = $1
`

	if _, err := p.DB.ExecContext(ctx, updateEpisode, id, processedURL, processedKey, sizeBytes, waveform, int(duration.Seconds())); err != nil {
		return err
	}

	return nil
}

func (p *Processor) downloadOriginal(ctx context.Context, storageKey, destPath string) error {
	reader, err := p.Storage.GetObject(ctx, storageKey)
	if err != nil {
		return err
	}
	defer reader.Close()

	out, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer out.Close()

	if _, err := io.Copy(out, reader); err != nil {
		return err
	}
	return out.Sync()
}

func (p *Processor) processWithFFmpeg(ctx context.Context, input, output, mask string) error {
	filter := "arnndn=m=rnnoise-models/rnnoise-model.bin,loudnorm=I=-16"
	switch mask {
	case "basic":
		filter += ",asetrate=48000*0.94,atempo=1.06"
	case "studio":
		filter += ",asetrate=48000*0.90,atempo=1.11"
	}

	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-y",
		"-i", input,
		"-af", filter,
		"-c:a", "libopus",
		"-b:a", "24k",
		"-ar", "48000",
		"-ac", "1",
		output,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func (p *Processor) extractMetadata(ctx context.Context, processedPath string) ([]byte, time.Duration, int64, error) {
	// duration
	cmd := exec.CommandContext(ctx, "ffprobe",
		"-v", "error",
		"-select_streams", "a:0",
		"-show_entries", "stream=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		processedPath,
	)
	output, err := cmd.Output()
	if err != nil {
		return nil, 0, 0, err
	}
	durationSeconds, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return nil, 0, 0, err
	}

	info, err := os.Stat(processedPath)
	if err != nil {
		return nil, 0, 0, err
	}

	peaks := make([]int, 64)
	waveform, err := json.Marshal(peaks)
	if err != nil {
		return nil, 0, 0, err
	}

	return waveform, time.Duration(durationSeconds * float64(time.Second)), info.Size(), nil
}

func (p *Processor) uploadProcessed(ctx context.Context, key, path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = p.Storage.PutObject(ctx, key, file, map[string]string{"processed": "true"})
	return err
}

func (p *Processor) markEpisodeFailed(ctx context.Context, episodeID string, procErr error) error {
	const update = `
UPDATE episodes
SET status = 'deleted',
    status_changed_at = now(),
    updated_at = now()
WHERE id = $1
`
	if _, err := p.DB.ExecContext(ctx, update, episodeID); err != nil {
		return err
	}

	reason := fmt.Sprintf("audio_processing_failed:%v", procErr)
	if err := p.insertModerationFlag(ctx, "episodes/"+episodeID, reason); err != nil {
		return err
	}
	return nil
}

func (p *Processor) insertModerationFlag(ctx context.Context, objectRef, reason string) error {
	const query = `
INSERT INTO moderation_flags (object_ref, severity, reason, status)
VALUES ($1, $2, $3, 'open')
ON CONFLICT DO NOTHING;
`
	_, err := p.DB.ExecContext(ctx, query, objectRef, 2, reason)
	return err
}
