package audio

import (
	"bufio"
	"bytes"
	"context"
	"database/sql"
	"encoding/binary"
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
SELECT id, storage_key, mask, quality, visibility
FROM episodes
WHERE id = $1 AND status = 'pending_public'
`

	var (
		id         uuid.UUID
		storageKey sql.NullString
		mask       string
		quality    string
		visibility string
	)

	if err := p.DB.QueryRowContext(ctx, selectEpisode, episodeID).Scan(&id, &storageKey, &mask, &quality, &visibility); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil
		}
		return err
	}

	if !storageKey.Valid || storageKey.String == "" {
		return errors.New("missing storage key for episode")
	}

	tempDir, err := os.MkdirTemp(p.MediaPath, "episode-*")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	originalPath := filepath.Join(tempDir, "original.webm")
	if err := p.downloadOriginal(ctx, storageKey.String, originalPath); err != nil {
		return err
	}

	processedPath := filepath.Join(tempDir, "processed.opus")
	waveformPath := filepath.Join(tempDir, "waveform.json")

	if err := p.processWithFFmpeg(ctx, originalPath, processedPath, mask); err != nil {
		return err
	}

	waveform, duration, sizeBytes, err := p.generateWaveform(ctx, processedPath, waveformPath)
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
	pr, pw := io.Pipe()
	defer pr.Close()

	go func() {
		defer pw.Close()
		_, err := p.Storage.PutObject(ctx, storageKey, bytes.NewReader([]byte{}), nil)
		if err != nil {
			pw.CloseWithError(err)
		}
	}()

	out, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, pr)
	return err
}

func (p *Processor) processWithFFmpeg(ctx context.Context, input, output, mask string) error {
	args := []string{
		"-y",
		"-i", input,
		"-af", "arnndn=m=rnnoise-models/rnnoise-model.bin,loudnorm=I=-16",
		"-c:a", "libopus",
		"-b:a", "24k",
		"-ar", "48000",
		"-ac", "1",
	}

	switch mask {
	case "basic":
		args = append(args, "-af", "asetrate=48000*0.94,atempo=1.06")
	case "studio":
		args = append(args, "-af", "asetrate=48000*0.90,atempo=1.11")
	}

	args = append(args, output)

	cmd := exec.CommandContext(ctx, "ffmpeg", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func (p *Processor) generateWaveform(ctx context.Context, processedPath, waveformPath string) ([]byte, time.Duration, int64, error) {
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

	waveCmd := exec.CommandContext(ctx, "ffmpeg",
		"-i", processedPath,
		"-filter_complex", "aformat=channel_layouts=mono,showwavespic=s=1000x50",
		"-frames:v", "1",
		"-f", "rawvideo",
		"-",
	)
	stdout, err := waveCmd.StdoutPipe()
	if err != nil {
		return nil, 0, 0, err
	}
	if err := waveCmd.Start(); err != nil {
		return nil, 0, 0, err
	}

	reader := bufio.NewReader(stdout)
	var peaks []int
	for {
		var sample int
		if err := binary.Read(reader, binary.LittleEndian, &sample); err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			return nil, 0, 0, err
		}
		peaks = append(peaks, sample)
	}

	if err := waveCmd.Wait(); err != nil {
		return nil, 0, 0, err
	}

	waveJSON, err := json.Marshal(peaks)
	if err != nil {
		return nil, 0, 0, err
	}

	info, err := os.Stat(processedPath)
	if err != nil {
		return nil, 0, 0, err
	}

	return waveJSON, time.Duration(durationSeconds * float64(time.Second)), info.Size(), nil
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
