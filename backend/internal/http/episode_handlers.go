package http

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/queue"
	"github.com/amunx/backend/internal/storage"
)

type episodeResponse struct {
	ID            string            `json:"id"`
	Status        string            `json:"status"`
	UploadURL     string            `json:"upload_url"`
	UploadHeaders map[string]string `json:"upload_headers,omitempty"`
}

func registerEpisodeRoutes(r chi.Router, deps *app.App) {
	r.Route("/episodes", func(er chi.Router) {
		er.Post("/", func(w http.ResponseWriter, req *http.Request) {
			var payload struct {
				Visibility  string  `json:"visibility"`
				TopicID     *string `json:"topic_id"`
				Mask        string  `json:"mask"`
				Quality     string  `json:"quality"`
				DurationSec *int    `json:"duration_sec"`
				ContentType string  `json:"content_type"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				writeError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}

			episodeID := uuid.New()
			key := "episodes/" + episodeID.String() + "/original"

			upload, err := deps.Storage.PresignUpload(req.Context(), key, 15*time.Minute, coalesceContentType(payload.ContentType))
			if err != nil {
				if errors.Is(err, storage.ErrNotImplemented) {
					writeError(w, http.StatusServiceUnavailable, "storage_disabled", "object storage not configured")
					return
				}
				writeError(w, http.StatusInternalServerError, "storage_error", err.Error())
				return
			}

			if err := createEpisode(req.Context(), deps.DB, createEpisodeParams{
				ID:          episodeID,
				Visibility:  normalizeVisibility(payload.Visibility, deps.Config),
				TopicID:     payload.TopicID,
				Mask:        normalizeMask(payload.Mask),
				Quality:     normalizeQuality(payload.Quality),
				DurationSec: payload.DurationSec,
				StorageKey:  key,
			}); err != nil {
				writeError(w, http.StatusInternalServerError, "episode_create_failed", err.Error())
				return
			}

			headers := map[string]string{}
			for k, values := range upload.Headers {
				if len(values) > 0 {
					headers[k] = values[0]
				}
			}

			writeJSON(w, http.StatusCreated, episodeResponse{
				ID:            episodeID.String(),
				Status:        "pending_upload",
				UploadURL:     upload.URL,
				UploadHeaders: headers,
			})
		})

		er.Post("/{id}/finalize", func(w http.ResponseWriter, req *http.Request) {
			episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
			if err != nil {
				writeError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
				return
			}

			if err := setEpisodeStatus(req.Context(), deps.DB, episodeID, "pending_public"); err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					writeError(w, http.StatusNotFound, "not_found", "episode not found")
					return
				}
				writeError(w, http.StatusInternalServerError, "episode_finalize_failed", err.Error())
				return
			}

			if err := deps.Queue.Enqueue(req.Context(), queue.TopicProcessAudio, map[string]any{
				"episode_id": episodeID.String(),
			}); err != nil {
				writeError(w, http.StatusInternalServerError, "enqueue_failed", err.Error())
				return
			}

			writeJSON(w, http.StatusOK, map[string]any{
				"status": "queued",
			})
		})

		er.Post("/{id}/undo", func(w http.ResponseWriter, req *http.Request) {
			episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
			if err != nil {
				writeError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
				return
			}

			ok, err := undoEpisode(req.Context(), deps.DB, episodeID, deps.Config.UndoSeconds)
			if err != nil {
				writeError(w, http.StatusInternalServerError, "undo_failed", err.Error())
				return
			}
			if !ok {
				writeError(w, http.StatusForbidden, "undo_window_elapsed", "undo window has expired or episode not pending")
				return
			}

			writeJSON(w, http.StatusOK, map[string]any{"status": "undone"})
		})
	})
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
	switch mask {
	case "none", "basic", "studio":
		return mask
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
	Visibility  string
	TopicID     *string
	Mask        string
	Quality     string
	DurationSec *int
	StorageKey  string
}

func createEpisode(ctx context.Context, db *sql.DB, params createEpisodeParams) error {
	const stmt = `
INSERT INTO episodes (id, visibility, topic_id, mask, quality, duration_sec, status, audio_url)
VALUES ($1, $2, $3, $4, $5, $6, 'pending_upload', $7);
`
	_, err := db.ExecContext(ctx, stmt,
		params.ID,
		params.Visibility,
		params.TopicID,
		params.Mask,
		params.Quality,
		params.DurationSec,
		params.StorageKey,
	)
	return err
}

func setEpisodeStatus(ctx context.Context, db *sql.DB, id uuid.UUID, status string) error {
	const stmt = `
UPDATE episodes
SET status = $2
WHERE id = $1
RETURNING id;
`
	var scanned uuid.UUID
	return db.QueryRowContext(ctx, stmt, id, status).Scan(&scanned)
}

func undoEpisode(ctx context.Context, db *sql.DB, id uuid.UUID, undoSeconds int) (bool, error) {
	const stmt = `
UPDATE episodes
SET status = 'deleted'
WHERE id = $1
  AND status = 'pending_public'
  AND now() - created_at <= ($2::int || ' seconds')::interval
RETURNING id;
`
	var scanned uuid.UUID
	err := db.QueryRowContext(ctx, stmt, id, undoSeconds).Scan(&scanned)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}
