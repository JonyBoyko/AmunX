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
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

const (
	consumerGroup     = "process_audio"
	finalizeGroup     = "finalize_live"
	maxAttempts       = 3
	maxFinalizeTrials = 3
)

type Processor struct {
	DB                 *sql.DB
	Storage            storage.Client
	Queue              queue.Stream
	Logger             zerolog.Logger
	CDNBase            string
	MediaPath          string
	ModerationKeywords []string
}

var defaultModerationKeywords = []string{
	"hate",
	"abuse",
	"violence",
	"kill",
	"weapon",
	"drugs",
	"terror",
	"self-harm",
}

func (p *Processor) Run(ctx context.Context, pollInterval time.Duration) error {
	if p.MediaPath == "" {
		p.MediaPath = os.TempDir()
	}
	if err := os.MkdirAll(p.MediaPath, 0o755); err != nil {
		return err
	}
	if len(p.ModerationKeywords) == 0 {
		p.ModerationKeywords = defaultModerationKeywords
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
		if err := p.claimAndFinalize(ctx, consumerName); err != nil {
			p.Logger.Error().Err(err).Msg("finalize loop error")
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

func (p *Processor) claimAndFinalize(ctx context.Context, consumer string) error {
	messages, err := p.Queue.Claim(ctx, queue.TopicFinalizeLive, finalizeGroup, consumer, 5)
	if err != nil {
		return err
	}
	if len(messages) == 0 {
		return nil
	}

	for _, msg := range messages {
		sessionIDStr := stringValue(msg.Values["session_id"])
		if sessionIDStr == "" {
			p.Logger.Warn().Interface("message", msg).Msg("missing session_id in finalize job")
			_ = p.Queue.Ack(ctx, queue.TopicFinalizeLive, finalizeGroup, msg.ID)
			continue
		}
		sessionID, err := uuid.Parse(sessionIDStr)
		if err != nil {
			p.Logger.Warn().Str("session_id", sessionIDStr).Msg("invalid session_id in finalize job")
			_ = p.Queue.Ack(ctx, queue.TopicFinalizeLive, finalizeGroup, msg.ID)
			continue
		}

		recordingKey := stringValue(msg.Values["recording_key"])
		var durationPtr *int
		if raw, ok := msg.Values["duration_sec"]; ok {
			if val, err := intValue(raw); err == nil {
				durationPtr = &val
			}
		}

		if err := p.handleFinalizeLive(ctx, sessionID, recordingKey, durationPtr); err != nil {
			attempt := parseAttempt(msg.Values["attempt"])
			p.Logger.Error().Err(err).Str("session_id", sessionID.String()).Int("attempt", attempt).Msg("finalize live failed")
			if attempt+1 >= maxFinalizeTrials {
				_ = p.Queue.Ack(ctx, queue.TopicFinalizeLive, finalizeGroup, msg.ID)
				continue
			}
			requeue := map[string]any{
				"session_id": sessionID.String(),
				"attempt":    attempt + 1,
			}
			if recordingKey != "" {
				requeue["recording_key"] = recordingKey
			}
			if durationPtr != nil {
				requeue["duration_sec"] = *durationPtr
			}
			if err := p.Queue.Enqueue(ctx, queue.TopicFinalizeLive, requeue); err != nil {
				p.Logger.Error().Err(err).Str("session_id", sessionID.String()).Msg("failed to requeue finalize job")
			}
			_ = p.Queue.Ack(ctx, queue.TopicFinalizeLive, finalizeGroup, msg.ID)
			continue
		}

		if err := p.Queue.Ack(ctx, queue.TopicFinalizeLive, finalizeGroup, msg.ID); err != nil {
			p.Logger.Error().Err(err).Str("session_id", sessionID.String()).Msg("failed to ack finalize job")
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

func stringValue(value any) string {
	switch v := value.(type) {
	case string:
		return v
	case fmt.Stringer:
		return v.String()
	default:
		return ""
	}
}

func intValue(value any) (int, error) {
	switch v := value.(type) {
	case int:
		return v, nil
	case int64:
		return int(v), nil
	case float64:
		return int(v), nil
	case string:
		if v == "" {
			return 0, fmt.Errorf("empty string")
		}
		n, err := strconv.Atoi(v)
		if err != nil {
			return 0, err
		}
		return n, nil
	default:
		return 0, fmt.Errorf("unsupported type %T", value)
	}
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

	summary, keywords, mood := generatePlaceholderSummary(mask, duration)
	if err := p.upsertSummary(ctx, id, summary, keywords, mood); err != nil {
		p.Logger.Warn().Err(err).Str("episode_id", episodeID).Msg("failed to upsert summary")
	}
	if hits := p.scanKeywordHits(summary, keywords); len(hits) > 0 {
		for _, word := range hits {
			reason := "keyword_hit:" + word
			if err := p.insertModerationFlag(ctx, "episodes/"+id.String(), reason); err != nil {
				p.Logger.Warn().Err(err).Str("episode_id", episodeID).Str("keyword", word).Msg("failed to record moderation flag")
			}
		}
	}

	return nil
}

func (p *Processor) handleFinalizeLive(ctx context.Context, sessionID uuid.UUID, recordingKey string, duration *int) error {
	session, err := p.loadLiveSession(ctx, sessionID)
	if err != nil {
		return err
	}
	if session.EpisodeExists {
		p.Logger.Info().Str("session_id", sessionID.String()).Msg("live session already finalized")
		return nil
	}

	key := strings.TrimSpace(recordingKey)
	if key == "" {
		key = strings.TrimSpace(session.RecordingKey)
	}
	if key == "" {
		return fmt.Errorf("recording key missing for session %s", sessionID)
	}

	if duration == nil && session.DurationSec != nil {
		duration = session.DurationSec
	}

	if err := p.ensureLiveMetadata(ctx, sessionID, key, duration); err != nil {
		return err
	}

	episodeID := uuid.New()
	var topic interface{}
	if session.TopicID != nil {
		topic = *session.TopicID
	}
	var durationValue interface{}
	if duration != nil {
		durationValue = *duration
	}
	title := session.Title
	if strings.TrimSpace(title) == "" {
		title = "Live session"
	}

	const insertEpisode = `
INSERT INTO episodes (id, author_id, topic_id, visibility, status, title, duration_sec, storage_key, mask, is_live, live_session_id)
VALUES ($1, $2, $3, 'public', 'pending_public', $4, $5, $6, $7, true, $8);
`
	_, err = p.DB.ExecContext(ctx, insertEpisode, episodeID, session.HostID, topic, title, durationValue, key, session.Mask, sessionID)
	if err != nil {
		if isUniqueViolation(err) {
			return nil
		}
		return err
	}

	if err := p.Queue.Enqueue(ctx, queue.TopicProcessAudio, map[string]any{
		"episode_id": episodeID.String(),
		"attempt":    0,
	}); err != nil {
		return err
	}

	return nil
}

type liveSessionRecord struct {
	ID            uuid.UUID
	HostID        uuid.UUID
	TopicID       *uuid.UUID
	RecordingKey  string
	DurationSec   *int
	Title         string
	Mask          string
	EpisodeExists bool
}

func (p *Processor) loadLiveSession(ctx context.Context, id uuid.UUID) (liveSessionRecord, error) {
	const query = `
SELECT ls.host_id, ls.topic_id, ls.recording_key, ls.duration_sec, ls.ended_at, ls.title, ls.mask, e.id
FROM live_sessions ls
LEFT JOIN episodes e ON e.live_session_id = ls.id
WHERE ls.id = $1;
`
	var (
		rec       liveSessionRecord
		hostID    uuid.UUID
		topic     sql.NullString
		recording sql.NullString
		duration  sql.NullInt64
		endedAt   sql.NullTime
		title     sql.NullString
		mask      string
		episode   sql.NullString
	)
	err := p.DB.QueryRowContext(ctx, query, id).Scan(&hostID, &topic, &recording, &duration, &endedAt, &title, &mask, &episode)
	if err != nil {
		return rec, err
	}
	if !endedAt.Valid {
		return rec, fmt.Errorf("live session %s not ended", id)
	}
	rec.ID = id
	rec.HostID = hostID
	if topic.Valid {
		if tid, err := uuid.Parse(topic.String); err == nil {
			topicID := tid
			rec.TopicID = &topicID
		}
	}
	if recording.Valid {
		rec.RecordingKey = recording.String
	}
	if duration.Valid {
		dur := int(duration.Int64)
		rec.DurationSec = &dur
	}
	if title.Valid {
		rec.Title = strings.TrimSpace(title.String)
	}
	rec.Mask = mask
	rec.EpisodeExists = episode.Valid
	return rec, nil
}

func (p *Processor) ensureLiveMetadata(ctx context.Context, sessionID uuid.UUID, recordingKey string, duration *int) error {
	var durationValue interface{}
	if duration != nil {
		durationValue = *duration
	}
	_, err := p.DB.ExecContext(ctx, `
UPDATE live_sessions
SET recording_key = COALESCE(NULLIF($2, ''), recording_key),
    duration_sec = COALESCE($3, duration_sec)
WHERE id = $1;
`, sessionID, recordingKey, durationValue)
	return err
}

func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "duplicate key")
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

func (p *Processor) upsertSummary(ctx context.Context, episodeID uuid.UUID, summary string, keywords []string, mood map[string]float64) error {
	moodJSON, err := json.Marshal(mood)
	if err != nil {
		return err
	}

	const query = `
INSERT INTO summaries (episode_id, tldr, keywords, mood)
VALUES ($1, $2, $3, $4)
ON CONFLICT (episode_id) DO UPDATE SET
	tldr = EXCLUDED.tldr,
	keywords = EXCLUDED.keywords,
	mood = EXCLUDED.mood
`
	_, err = p.DB.ExecContext(ctx, query, episodeID, summary, pq.Array(keywords), moodJSON)
	return err
}

func (p *Processor) scanKeywordHits(summary string, keywords []string) []string {
	if len(p.ModerationKeywords) == 0 {
		return nil
	}
	lowerSummary := strings.ToLower(summary)
	seen := make(map[string]struct{})

	check := func(candidate string) {
		candidate = strings.ToLower(candidate)
		for _, banned := range p.ModerationKeywords {
			bannedLower := strings.ToLower(strings.TrimSpace(banned))
			if bannedLower == "" {
				continue
			}
			if strings.Contains(candidate, bannedLower) {
				seen[bannedLower] = struct{}{}
			}
		}
	}

	check(lowerSummary)
	for _, kw := range keywords {
		check(kw)
	}

	if len(seen) == 0 {
		return nil
	}
	result := make([]string, 0, len(seen))
	for word := range seen {
		result = append(result, word)
	}
	sort.Strings(result)
	return result
}

func generatePlaceholderSummary(mask string, duration time.Duration) (string, []string, map[string]float64) {
	base := "Voice note"
	switch mask {
	case "basic":
		base = "Lightly masked voice note"
	case "studio":
		base = "Studio treated voice note"
	}

	minutes := int(duration.Seconds()) / 60
	if minutes > 0 {
		base = fmt.Sprintf("%s (~%d min)", base, minutes)
	}

	keywords := []string{"voice", "note"}
	if mask != "none" {
		keywords = append(keywords, mask)
	}

	mood := map[string]float64{
		"valence": 0.1,
		"arousal": 0.3,
	}

	return base, keywords, mood
}
