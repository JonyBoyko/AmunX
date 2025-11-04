package http

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	livekitauth "github.com/livekit/protocol/auth"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
	"github.com/amunx/backend/internal/queue"
)

func registerLiveRoutes(r chi.Router, deps *app.App) {
	r.Post("/live/sessions", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		if user.Shadowbanned {
			WriteError(w, http.StatusForbidden, "account_restricted", "live streaming is disabled for this account")
			return
		}
		if !deps.Config.FeatureLiveRecording {
			WriteError(w, http.StatusForbidden, "feature_disabled", "live sessions are temporarily disabled")
			return
		}

		var payload struct {
			TopicID *string `json:"topic_id"`
			Title   string  `json:"title"`
		}
		if err := decodeJSON(req, &payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}

		var topicID *uuid.UUID
		if payload.TopicID != nil && *payload.TopicID != "" {
			tID, err := uuid.Parse(*payload.TopicID)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_topic_id", "topic_id must be a valid UUID")
				return
			}
			if err := ensureTopicAccessible(req.Context(), deps.DB, tID, user.ID); err != nil {
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
			topicID = &tID
		}

		sessionID := uuid.New()
		roomName := fmt.Sprintf("live-%s", sessionID.String())
		now := time.Now().UTC()
		title := strings.TrimSpace(payload.Title)

		if err := createLiveSession(req.Context(), deps.DB, sessionID, user.ID, topicID, roomName, title, now); err != nil {
			WriteError(w, http.StatusInternalServerError, "live_create_failed", err.Error())
			return
		}

		token, err := generateLiveToken(deps.Config, roomName, user.ID.String(), "host", now.Add(1*time.Hour))
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "token_generation_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusCreated, map[string]any{
			"session": map[string]any{
				"id":         sessionID.String(),
				"room":       roomName,
				"host_id":    user.ID.String(),
				"topic_id":   payload.TopicID,
				"title":      title,
				"started_at": now.Format(time.RFC3339),
			},
			"token": token,
			"url":   deps.Config.LiveKitURL,
		})
	})

	r.Post("/live/sessions/{id}/end", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		sessionID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_session_id", err.Error())
			return
		}

		session, err := getActiveLiveSession(req.Context(), deps.DB, sessionID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "session_not_found", "live session not found or already ended")
				return
			}
			WriteError(w, http.StatusInternalServerError, "session_lookup_failed", err.Error())
			return
		}

		if session.HostID != user.ID.String() {
			WriteError(w, http.StatusForbidden, "forbidden", "only host can end session")
			return
		}

		var payload struct {
			RecordingKey string `json:"recording_key"`
			DurationSec  *int   `json:"duration_sec"`
		}
		if req.Body != nil && req.ContentLength != 0 {
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}
		}

		now := time.Now().UTC()
		recordingKey := strings.TrimSpace(payload.RecordingKey)
		if err := markLiveSessionEnded(req.Context(), deps.DB, sessionID, now, recordingKey, payload.DurationSec); err != nil {
			WriteError(w, http.StatusInternalServerError, "session_end_failed", err.Error())
			return
		}

		job := map[string]any{
			"session_id": sessionID.String(),
			"attempt":    0,
		}
		if recordingKey != "" {
			job["recording_key"] = recordingKey
		}
		if payload.DurationSec != nil {
			job["duration_sec"] = *payload.DurationSec
		}

		if err := deps.Queue.Enqueue(req.Context(), queue.TopicFinalizeLive, job); err != nil {
			WriteError(w, http.StatusInternalServerError, "finalize_enqueue_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"status":    "ended",
			"ended_at":  now.Format(time.RFC3339),
			"sessionId": sessionID.String(),
		})
	})
}

func registerPublicLiveRoutes(r chi.Router, deps *app.App) {
	r.Get("/live/sessions/{id}", func(w http.ResponseWriter, req *http.Request) {
		sessionID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_session_id", err.Error())
			return
		}
		role := strings.ToLower(strings.TrimSpace(req.URL.Query().Get("role")))
		if role == "" {
			role = "listener"
		}
		if role != "listener" && role != "host" {
			WriteError(w, http.StatusBadRequest, "invalid_role", "role must be host or listener")
			return
		}

		session, err := getActiveLiveSession(req.Context(), deps.DB, sessionID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "session_not_found", "live session not found or ended")
				return
			}
			WriteError(w, http.StatusInternalServerError, "session_lookup_failed", err.Error())
			return
		}

		userID := uuid.New().String()
		if user, ok := httpctx.UserFromContext(req.Context()); ok {
			if user.Shadowbanned {
				WriteError(w, http.StatusForbidden, "account_restricted", "access denied")
				return
			}
			userID = user.ID.String()
		}

		expiry := time.Now().UTC().Add(2 * time.Hour)
		token, err := generateLiveToken(deps.Config, session.Room, userID, role, expiry)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "token_generation_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"session": session,
			"token":   token,
			"url":     deps.Config.LiveKitURL,
		})
	})
}

func createLiveSession(ctx context.Context, db *sql.DB, id, hostID uuid.UUID, topicID *uuid.UUID, room string, title string, started time.Time) error {
	const query = `
INSERT INTO live_sessions (id, host_id, topic_id, sfu_room, title, started_at, ended_at)
VALUES ($1, $2, $3, $4, $5, $6, NULL);
`
	var topic interface{}
	if topicID != nil {
		topic = *topicID
	}
	_, err := db.ExecContext(ctx, query, id, hostID, topic, room, title, started)
	return err
}

type liveSessionView struct {
	ID        uuid.UUID `json:"id"`
	HostID    string    `json:"host_id"`
	TopicID   *string   `json:"topic_id,omitempty"`
	Room      string    `json:"room"`
	Title     *string   `json:"title,omitempty"`
	StartedAt string    `json:"started_at"`
	EndedAt   *string   `json:"ended_at,omitempty"`
}

func getActiveLiveSession(ctx context.Context, db *sql.DB, id uuid.UUID) (liveSessionView, error) {
	const query = `
SELECT id, host_id, topic_id, sfu_room, title, started_at, ended_at
FROM live_sessions
WHERE id = $1;
`
	var (
		rec       liveSessionView
		hostID    uuid.UUID
		topic     sql.NullString
		title     sql.NullString
		startedAt time.Time
		endedAt   sql.NullTime
	)
	err := db.QueryRowContext(ctx, query, id).Scan(&rec.ID, &hostID, &topic, &rec.Room, &title, &startedAt, &endedAt)
	if err != nil {
		return liveSessionView{}, err
	}
	if endedAt.Valid {
		return liveSessionView{}, sql.ErrNoRows
	}
	rec.HostID = hostID.String()
	if topic.Valid {
		rec.TopicID = &topic.String
	}
	if title.Valid {
		rec.Title = &title.String
	}
	rec.StartedAt = startedAt.Format(time.RFC3339)
	return rec, nil
}

func markLiveSessionEnded(ctx context.Context, db *sql.DB, id uuid.UUID, ended time.Time, recordingKey string, durationSec *int) error {
	const query = `
UPDATE live_sessions
SET ended_at = $2,
    recording_key = COALESCE(NULLIF($3, ''), recording_key),
    duration_sec = COALESCE($4, duration_sec)
WHERE id = $1 AND ended_at IS NULL;
`
	var duration interface{}
	if durationSec != nil {
		duration = *durationSec
	}
	res, err := db.ExecContext(ctx, query, id, ended, recordingKey, duration)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func generateLiveToken(cfg app.Config, roomName, userID, role string, expiry time.Time) (string, error) {
	if cfg.LiveKitAPIKey == "" || cfg.LiveKitAPISecret == "" {
		payload := fmt.Sprintf("%s|%s|%s|%d", roomName, userID, role, expiry.Unix())
		mac := hmac.New(sha256.New, []byte("dev-secret"))
		mac.Write([]byte(payload))
		sig := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
		return base64.RawURLEncoding.EncodeToString([]byte(payload)) + "." + sig, nil
	}

	duration := time.Until(expiry)
	if duration <= 0 {
		duration = time.Minute * 10
	}

	videoGrant := &livekitauth.VideoGrant{
		RoomJoin: true,
		Room:     roomName,
	}
	videoGrant.SetCanSubscribe(true)
	if role == "host" {
		videoGrant.RoomAdmin = true
		videoGrant.SetCanPublish(true)
		videoGrant.SetCanPublishData(true)
	} else {
		videoGrant.SetCanPublishData(true)
	}

	token := livekitauth.NewAccessToken(cfg.LiveKitAPIKey, cfg.LiveKitAPISecret).
		SetIdentity(userID).
		SetValidFor(duration).
		AddGrant(videoGrant)

	return token.ToJWT()
}
