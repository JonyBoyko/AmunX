package http

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

type episodeResponse struct {
	ID            string            `json:"id"`
	Status        string            `json:"status"`
	UploadURL     string            `json:"upload_url"`
	UploadHeaders map[string]string `json:"upload_headers,omitempty"`
}

const (
	episodeUserRateLimit int64 = 6
)

var (
	episodeUserRateWindow       = 5 * time.Minute
	episodeIPRateLimit    int64 = 20
	episodeIPRateWindow         = 10 * time.Minute
)

type episodeSummary struct {
	ID          string         `json:"id"`
	AuthorID    string         `json:"author_id"`
	TopicID     *string        `json:"topic_id,omitempty"`
	Title       *string        `json:"title,omitempty"`
	Visibility  string         `json:"visibility"`
	Status      string         `json:"status"`
	DurationSec *int           `json:"duration_sec,omitempty"`
	AudioURL    *string        `json:"audio_url,omitempty"`
	Mask        string         `json:"mask"`
	Quality     string         `json:"quality"`
	IsLive      bool           `json:"is_live"`
	PublishedAt *time.Time     `json:"published_at,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	Summary     *string        `json:"summary,omitempty"`
	Keywords    []string       `json:"keywords,omitempty"`
	Mood        map[string]any `json:"mood,omitempty"`
}

func registerEpisodeRoutes(r chi.Router, deps *app.App) {
	r.Post("/episodes", func(w http.ResponseWriter, req *http.Request) {
			currentUser, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}
			if currentUser.Shadowbanned {
				WriteError(w, http.StatusForbidden, "account_restricted", "publishing is disabled for this account")
				return
			}

			if allowed, retry := allowRate(req.Context(), deps.Redis, "rl:episodes:user:"+currentUser.ID.String(), episodeUserRateLimit, episodeUserRateWindow); !allowed {
				if retry > 0 {
					w.Header().Set("Retry-After", strconv.FormatInt(int64((retry+time.Second-1)/time.Second), 10))
				}
				WriteError(w, http.StatusTooManyRequests, "rate_limited", "too many episodes created recently")
				return
			}
			if ip := clientIP(req); ip != "" {
				if allowed, retry := allowRate(req.Context(), deps.Redis, "rl:episodes:ip:"+ip, episodeIPRateLimit, episodeIPRateWindow); !allowed {
					if retry > 0 {
						w.Header().Set("Retry-After", strconv.FormatInt(int64((retry+time.Second-1)/time.Second), 10))
					}
					WriteError(w, http.StatusTooManyRequests, "rate_limited", "too many episodes from this network")
					return
				}
			}

			var payload struct {
				Visibility  string  `json:"visibility"`
				TopicID     *string `json:"topic_id"`
				Mask        string  `json:"mask"`
				Quality     string  `json:"quality"`
				DurationSec *int    `json:"duration_sec"`
				ContentType string  `json:"content_type"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}

			var topicID *uuid.UUID
			if payload.TopicID != nil {
				parsed, err := uuid.Parse(*payload.TopicID)
				if err != nil {
					WriteError(w, http.StatusBadRequest, "invalid_topic_id", "topic_id must be a valid UUID")
					return
				}
				topicID = &parsed
			}

			episodeID := uuid.New()
			key := "episodes/" + episodeID.String() + "/original"

			upload, err := deps.Storage.PresignUpload(req.Context(), key, 15*time.Minute, coalesceContentType(payload.ContentType))
			if err != nil {
				if errors.Is(err, storage.ErrNotImplemented) {
					WriteError(w, http.StatusServiceUnavailable, "storage_disabled", "object storage not configured")
					return
				}
				WriteError(w, http.StatusInternalServerError, "storage_error", err.Error())
				return
			}

			if topicID != nil {
				if err := ensureTopicAccessible(req.Context(), deps.DB, *topicID, currentUser.ID); err != nil {
					switch {
					case errors.Is(err, sql.ErrNoRows):
						WriteError(w, http.StatusNotFound, "topic_not_found", "topic does not exist")
						return
					case errors.Is(err, errTopicNotAccessible):
						WriteError(w, http.StatusForbidden, "topic_not_accessible", err.Error())
						return
					default:
						WriteError(w, http.StatusInternalServerError, "topic_validation_failed", err.Error())
						return
					}
				}
			}

			if err := createEpisode(req.Context(), deps.DB, createEpisodeParams{
				ID:          episodeID,
				AuthorID:    currentUser.ID,
				Visibility:  normalizeVisibility(payload.Visibility, deps.Config),
				TopicID:     topicID,
				Mask:        normalizeMask(payload.Mask),
				Quality:     normalizeQuality(payload.Quality),
				DurationSec: payload.DurationSec,
				StorageKey:  key,
			}); err != nil {
				WriteError(w, http.StatusInternalServerError, "episode_create_failed", err.Error())
				return
			}

			headers := map[string]string{}
			for k, values := range upload.Headers {
				if len(values) > 0 {
					headers[k] = values[0]
				}
			}

			WriteJSON(w, http.StatusCreated, episodeResponse{
				ID:            episodeID.String(),
				Status:        "pending_upload",
				UploadURL:     upload.URL,
			UploadHeaders: headers,
		})
	})

	r.Post("/episodes/{id}/finalize", func(w http.ResponseWriter, req *http.Request) {
			currentUser, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}

			episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
				return
			}

			if err := setEpisodeStatus(req.Context(), deps.DB, episodeID, currentUser.ID, "pending_public"); err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					WriteError(w, http.StatusNotFound, "not_found", "episode not found")
					return
				}
				WriteError(w, http.StatusInternalServerError, "episode_finalize_failed", err.Error())
				return
			}

			if err := deps.Queue.Enqueue(req.Context(), queue.TopicProcessAudio, map[string]any{
				"episode_id": episodeID.String(),
				"attempt":    0,
			}); err != nil {
				WriteError(w, http.StatusInternalServerError, "enqueue_failed", err.Error())
				return
			}

			WriteJSON(w, http.StatusOK, map[string]any{
			"status": "queued",
		})
	})

	r.Post("/episodes/{id}/undo", func(w http.ResponseWriter, req *http.Request) {
			currentUser, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}

			episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
				return
			}

			okUndo, err := undoEpisode(req.Context(), deps.DB, episodeID, currentUser.ID, deps.Config.UndoSeconds)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "undo_failed", err.Error())
				return
			}
			if !okUndo {
				WriteError(w, http.StatusForbidden, "undo_window_elapsed", "undo window has expired or episode not pending")
				return
			}

			WriteJSON(w, http.StatusOK, map[string]any{"status": "undone"})
	})

	r.Post("/episodes/dev", handleDevEpisodeUpload(deps))
}

func normalizeVisibility(v string, cfg app.Config) string {
	switch v {
	case "public", "private", "anon":
		return v
	default:
		if cfg.PublicByDefault {
			return "public"
		}
		return "private"
	}
}

func normalizeMask(mask string) string {
	switch strings.ToLower(strings.TrimSpace(mask)) {
	case "basic":
		return "basic"
	case "studio":
		return "studio"
	default:
		return "none"
	}
}

func normalizeQuality(q string) string {
	switch q {
	case "raw", "clean", "studio":
		return q
	default:
		return "clean"
	}
}

func coalesceContentType(ct string) string {
	if ct == "" {
		return "audio/webm"
	}
	return ct
}

func uuidFromParam(value string) (uuid.UUID, error) {
	return uuid.Parse(value)
}

type createEpisodeParams struct {
	ID          uuid.UUID
	AuthorID    uuid.UUID
	Visibility  string
	TopicID     *uuid.UUID
	Mask        string
	Quality     string
	DurationSec *int
	StorageKey  string
}

func createEpisode(ctx context.Context, db *sql.DB, params createEpisodeParams) error {
	const stmt = `
INSERT INTO episodes (id, author_id, topic_id, visibility, mask, quality, duration_sec, storage_key)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
`
	var (
		topic    interface{}
		duration interface{}
	)
	if params.TopicID != nil {
		topic = *params.TopicID
	}
	if params.DurationSec != nil {
		duration = *params.DurationSec
	}

	_, err := db.ExecContext(ctx, stmt,
		params.ID,
		params.AuthorID,
		topic,
		params.Visibility,
		params.Mask,
		params.Quality,
		duration,
		params.StorageKey,
	)
	return err
}

func setEpisodeStatus(ctx context.Context, db *sql.DB, id uuid.UUID, author uuid.UUID, status string) error {
	const stmt = `
UPDATE episodes
SET status = $2,
    status_changed_at = now(),
    updated_at = now(),
    published_at = CASE WHEN $2 = 'public' THEN now() ELSE published_at END
WHERE id = $1
  AND author_id = $3
RETURNING id;
`
	var scanned uuid.UUID
	return db.QueryRowContext(ctx, stmt, id, status, author).Scan(&scanned)
}

func undoEpisode(ctx context.Context, db *sql.DB, id uuid.UUID, author uuid.UUID, undoSeconds int) (bool, error) {
	const stmt = `
UPDATE episodes
SET status = 'deleted',
    status_changed_at = now(),
    updated_at = now()
WHERE id = $1
  AND author_id = $3
  AND status = 'pending_public'
  AND now() - status_changed_at <= ($2::int || ' seconds')::interval
RETURNING id;
`
	var scanned uuid.UUID
	err := db.QueryRowContext(ctx, stmt, id, undoSeconds, author).Scan(&scanned)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

func ensureTopicAccessible(ctx context.Context, db *sql.DB, topicID uuid.UUID, userID uuid.UUID) error {
	const query = `SELECT owner_id, is_public FROM topics WHERE id = $1`
	var (
		owner    uuid.UUID
		isPublic bool
	)
	if err := db.QueryRowContext(ctx, query, topicID).Scan(&owner, &isPublic); err != nil {
		return err
	}
	if !isPublic && owner != userID {
		return errTopicNotAccessible
	}
	return nil
}

func registerPublicEpisodeRoutes(r chi.Router, deps *app.App) {
	r.Get("/episodes", func(w http.ResponseWriter, req *http.Request) {
		ctx := req.Context()

		limit := parseLimit(req.URL.Query().Get("limit"), 20, 50)
		var (
			topicID  *uuid.UUID
			authorID *uuid.UUID
			after    *time.Time
		)

		if topic := req.URL.Query().Get("topic"); topic != "" {
			id, err := uuid.Parse(topic)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_topic_id", "topic must be a valid UUID")
				return
			}
			topicID = &id
		}

		if author := req.URL.Query().Get("author"); author != "" {
			id, err := uuid.Parse(author)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_author_id", "author must be a valid UUID")
				return
			}
			authorID = &id
		}

		if afterParam := req.URL.Query().Get("after"); afterParam != "" {
			ts, err := time.Parse(time.RFC3339, afterParam)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_after", "after must be RFC3339 timestamp")
				return
			}
			after = &ts
		}

		items, err := listPublicEpisodes(ctx, deps.DB, listEpisodesParams{
			Limit:    limit,
			TopicID:  topicID,
			AuthorID: authorID,
			After:    after,
		})
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "episodes_list_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"items": items,
		})
	})

	r.Get("/episodes/{id}", func(w http.ResponseWriter, req *http.Request) {
		ctx := req.Context()
		episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}

		episode, err := getEpisodeByID(ctx, deps.DB, episodeID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "not_found", "episode not found")
				return
			}
			WriteError(w, http.StatusInternalServerError, "episode_fetch_failed", err.Error())
			return
		}

		currentUser, ok := httpctx.UserFromContext(ctx)
		if episode.Status != "public" && (!ok || currentUser.ID.String() != episode.AuthorID) {
			WriteError(w, http.StatusForbidden, "forbidden", "episode not available")
			return
		}

		WriteJSON(w, http.StatusOK, episode)
	})

	r.Get("/dev/audio/{episodeID}", handleServeDevAudio(deps))
}

type devEpisodeParams struct {
	ID          uuid.UUID
	AuthorID    uuid.UUID
	TopicID     *uuid.UUID
	Title       string
	DurationSec *int
	StorageKey  string
	AudioURL    string
}

func insertDevEpisode(ctx context.Context, db *sql.DB, params devEpisodeParams) error {
	const stmt = `
INSERT INTO episodes (id, author_id, topic_id, visibility, status, title, duration_sec, storage_key, audio_url, mask, quality, published_at, created_at, updated_at)
VALUES ($1, $2, $3, 'public', 'public', $4, $5, $6, $7, 'none', 'clean', NOW(), NOW(), NOW());
`
	var topic interface{}
	if params.TopicID != nil {
		topic = *params.TopicID
	}
	var duration interface{}
	if params.DurationSec != nil {
		duration = *params.DurationSec
	}

	_, err := db.ExecContext(ctx, stmt,
		params.ID,
		params.AuthorID,
		topic,
		params.Title,
		duration,
		params.StorageKey,
		params.AudioURL,
	)
	return err
}

func handleDevEpisodeUpload(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		if err := req.ParseMultipartForm(64 << 20); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", "unable to parse form")
			return
		}

		file, header, err := req.FormFile("file")
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_file", "audio file is required")
			return
		}
		defer file.Close()

		title := strings.TrimSpace(req.FormValue("title"))
		if title == "" {
			title = "Moweton Entry"
		}

		var duration *int
		if d := strings.TrimSpace(req.FormValue("duration")); d != "" {
			if seconds, err := strconv.Atoi(d); err == nil {
				duration = &seconds
			}
		}

		var topicID *uuid.UUID
		if topicStr := strings.TrimSpace(req.FormValue("topic_id")); topicStr != "" {
			parsed, err := uuid.Parse(topicStr)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_topic_id", "topic_id must be a valid UUID")
				return
			}
			if err := ensureTopicAccessible(req.Context(), deps.DB, parsed, currentUser.ID); err != nil {
				WriteError(w, http.StatusForbidden, "topic_not_accessible", err.Error())
				return
			}
			topicID = &parsed
		}

		episodeID := uuid.New()
		ext := strings.ToLower(filepath.Ext(header.Filename))
		if ext == "" {
			ext = ".m4a"
		}
		storageKey := filepath.Join("dev", episodeID.String()+ext)
		absPath := filepath.Join(deps.Config.LocalMediaPath, storageKey)

		if err := os.MkdirAll(filepath.Dir(absPath), 0o755); err != nil {
			WriteError(w, http.StatusInternalServerError, "storage_error", err.Error())
			return
		}

		dst, err := os.Create(absPath)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "storage_error", err.Error())
			return
		}
		defer dst.Close()

		if _, err := io.Copy(dst, file); err != nil {
			WriteError(w, http.StatusInternalServerError, "storage_error", err.Error())
			return
		}

		audioURL := fmt.Sprintf("/v1/dev/audio/%s", episodeID.String())
		if err := insertDevEpisode(req.Context(), deps.DB, devEpisodeParams{
			ID:          episodeID,
			AuthorID:    currentUser.ID,
			TopicID:     topicID,
			Title:       title,
			DurationSec: duration,
			StorageKey:  storageKey,
			AudioURL:    audioURL,
		}); err != nil {
			WriteError(w, http.StatusInternalServerError, "episode_create_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusCreated, map[string]any{
			"id":        episodeID.String(),
			"audio_url": audioURL,
			"status":    "public",
		})
	}
}

func handleServeDevAudio(deps *app.App) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		episodeID, err := uuidFromParam(chi.URLParam(req, "episodeID"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}

		const query = `SELECT storage_key FROM episodes WHERE id = $1`
		var storageKey sql.NullString
		if err := deps.DB.QueryRowContext(req.Context(), query, episodeID).Scan(&storageKey); err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "not_found", "episode not found")
				return
			}
			WriteError(w, http.StatusInternalServerError, "storage_error", err.Error())
			return
		}
		if !storageKey.Valid || !strings.HasPrefix(storageKey.String, "dev/") {
			WriteError(w, http.StatusNotFound, "not_found", "dev audio not found")
			return
		}

		path := filepath.Join(deps.Config.LocalMediaPath, storageKey.String)
		if _, err := os.Stat(path); err != nil {
			WriteError(w, http.StatusNotFound, "not_found", "audio file missing")
			return
		}

		http.ServeFile(w, req, path)
	}
}

type listEpisodesParams struct {
	Limit    int
	TopicID  *uuid.UUID
	AuthorID *uuid.UUID
	After    *time.Time
}

func parseLimit(raw string, def, max int) int {
	if raw == "" {
		return def
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n <= 0 {
		return def
	}
	if n > max {
		return max
	}
	return n
}

func listPublicEpisodes(ctx context.Context, db *sql.DB, params listEpisodesParams) ([]episodeSummary, error) {
	query := `SELECT e.id, e.author_id, e.topic_id, e.title, e.visibility, e.status, e.duration_sec, e.audio_url, e.mask, e.quality, e.is_live, e.published_at, e.created_at, s.tldr, s.keywords, s.mood
FROM episodes e
LEFT JOIN summaries s ON s.episode_id = e.id
WHERE e.status = 'public'`
	var (
		args   []any
		cursor = 1
	)
	if params.TopicID != nil {
		query += fmt.Sprintf(" AND e.topic_id = $%d", cursor)
		args = append(args, *params.TopicID)
		cursor++
	}
	if params.AuthorID != nil {
		query += fmt.Sprintf(" AND e.author_id = $%d", cursor)
		args = append(args, *params.AuthorID)
		cursor++
	}
	if params.After != nil {
		query += fmt.Sprintf(" AND e.published_at < $%d", cursor)
		args = append(args, *params.After)
		cursor++
	}

	query += " ORDER BY e.published_at DESC NULLS LAST, e.created_at DESC"
	query += fmt.Sprintf(" LIMIT $%d", cursor)
	args = append(args, params.Limit)

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []episodeSummary
	for rows.Next() {
		var (
			rec         episodeSummary
			topicID     sql.NullString
			title       sql.NullString
			duration    sql.NullInt64
			audioURL    sql.NullString
			publishedAt sql.NullTime
			authorUUID  uuid.UUID
			tldr        sql.NullString
			keywordsArr pq.StringArray
			moodJSON    sql.NullString
		)
		if err := rows.Scan(
			&rec.ID,
			&authorUUID,
			&topicID,
			&title,
			&rec.Visibility,
			&rec.Status,
			&duration,
			&audioURL,
			&rec.Mask,
			&rec.Quality,
			&rec.IsLive,
			&publishedAt,
			&rec.CreatedAt,
			&tldr,
			&keywordsArr,
			&moodJSON,
		); err != nil {
			return nil, err
		}
		rec.AuthorID = authorUUID.String()
		if topicID.Valid {
			rec.TopicID = &topicID.String
		}
		if title.Valid {
			rec.Title = &title.String
		}
		if duration.Valid {
			val := int(duration.Int64)
			rec.DurationSec = &val
		}
		if audioURL.Valid {
			url := audioURL.String
			rec.AudioURL = &url
		}
		if publishedAt.Valid {
			rec.PublishedAt = &publishedAt.Time
		}
		if tldr.Valid {
			rec.Summary = &tldr.String
		}
		if len(keywordsArr) > 0 {
			rec.Keywords = append(rec.Keywords, keywordsArr...)
		}
		if moodJSON.Valid {
			var mood map[string]any
			if err := json.Unmarshal([]byte(moodJSON.String), &mood); err == nil {
				rec.Mood = mood
			}
		}
		results = append(results, rec)
	}
	return results, rows.Err()
}

func getEpisodeByID(ctx context.Context, db *sql.DB, id uuid.UUID) (episodeSummary, error) {
	const query = `SELECT e.id, e.author_id, e.topic_id, e.title, e.visibility, e.status, e.duration_sec, e.audio_url, e.mask, e.quality, e.is_live, e.published_at, e.created_at, s.tldr, s.keywords, s.mood
FROM episodes e
LEFT JOIN summaries s ON s.episode_id = e.id
WHERE e.id = $1`
	var (
		rec         episodeSummary
		topicID     sql.NullString
		title       sql.NullString
		duration    sql.NullInt64
		audioURL    sql.NullString
		publishedAt sql.NullTime
		authorUUID  uuid.UUID
		tldr        sql.NullString
		keywordsArr pq.StringArray
		moodJSON    sql.NullString
	)
	err := db.QueryRowContext(ctx, query, id).Scan(
		&rec.ID,
		&authorUUID,
		&topicID,
		&title,
		&rec.Visibility,
		&rec.Status,
		&duration,
		&audioURL,
		&rec.Mask,
		&rec.Quality,
		&rec.IsLive,
		&publishedAt,
		&rec.CreatedAt,
		&tldr,
		&keywordsArr,
		&moodJSON,
	)
	if err != nil {
		return episodeSummary{}, err
	}
	rec.AuthorID = authorUUID.String()
	if topicID.Valid {
		rec.TopicID = &topicID.String
	}
	if title.Valid {
		rec.Title = &title.String
	}
	if duration.Valid {
		val := int(duration.Int64)
		rec.DurationSec = &val
	}
	if audioURL.Valid {
		url := audioURL.String
		rec.AudioURL = &url
	}
	if publishedAt.Valid {
		rec.PublishedAt = &publishedAt.Time
	}
	if tldr.Valid {
		rec.Summary = &tldr.String
	}
	if len(keywordsArr) > 0 {
		rec.Keywords = append(rec.Keywords, keywordsArr...)
	}
	if moodJSON.Valid {
		var mood map[string]any
		if err := json.Unmarshal([]byte(moodJSON.String), &mood); err == nil {
			rec.Mood = mood
		}
	}
	return rec, nil
}

