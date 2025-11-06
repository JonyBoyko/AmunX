package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// RecordFeedEventRequest represents a feed event submission
type RecordFeedEventRequest struct {
	AudioID string                 `json:"audio_id"`
	Event   string                 `json:"event"` // impression, preview_finished, play, complete, save, share, quote, follow_author
	Meta    map[string]interface{} `json:"meta"`
}

// Valid event types
var validEventTypes = map[string]bool{
	"impression":       true,
	"preview_finished": true,
	"play":             true,
	"complete":         true,
	"save":             true,
	"share":            true,
	"quote":            true,
	"follow_author":    true,
}

// RecordFeedEvent records a user engagement event (POST /events)
func RecordFeedEvent(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	// Anonymous events allowed for impressions, but authenticated for most others
	// For MVP, we'll require auth for all events

	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req RecordFeedEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid_request")
		return
	}

	// Validate event type
	if !validEventTypes[req.Event] {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid event type")
		return
	}

	// Validate audio_id
	audioUUID, err := uuid.Parse(req.AudioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio_id")
		return
	}

	// Convert meta to JSONB
	metaJSON, err := json.Marshal(req.Meta)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid meta")
		return
	}

	_ = audioUUID
	_ = metaJSON

	// TODO: Insert event using sqlc RecordFeedEvent
	// INSERT INTO feed_events (user_id, audio_id, event, meta) VALUES (...)

	// Rate limiting: 100 events/minute per user
	// TODO: Implement rate limiting using Redis

	w.WriteHeader(http.StatusNoContent)
}

// GetAudioItemEventStats returns aggregated event stats for an audio item (internal/debug)
func GetAudioItemEventStats(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	_ = audioUUID

	// TODO: Fetch event counts using sqlc GetAudioItemEventCounts
	// SELECT COUNT(*) FILTER (WHERE event = 'impression') as impressions, ... FROM feed_events WHERE audio_id = $1

	stats := map[string]interface{}{
		"impressions":       100,
		"previews_finished": 75,
		"plays":             50,
		"completes":         40,
		"saves":             15,
		"shares":            8,
		"quotes":            3,
		"follows":           2,
	}

	WriteJSON(w, http.StatusOK, stats)
}

// registerFeedEventRoutes registers routes for feed events
func registerFeedEventRoutes(r chi.Router, deps *app.App) {
	r.Post("/events", func(w http.ResponseWriter, req *http.Request) {
		RecordFeedEvent(w, req, deps)
	})

	// Debug endpoint (should be protected in production)
	r.Get("/audio/{id}/events/stats", func(w http.ResponseWriter, req *http.Request) {
		GetAudioItemEventStats(w, req, deps)
	})
}


