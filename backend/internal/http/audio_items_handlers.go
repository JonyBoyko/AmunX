package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// CreateAudioItemRequest represents the request to create a new audio item
type CreateAudioItemRequest struct {
	S3Key             string   `json:"s3_key"`
	DurationSec       int      `json:"duration_sec"`
	Kind              string   `json:"kind"` // micro or podcast_episode
	Title             string   `json:"title"`
	Description       string   `json:"description"`
	Tags              []string `json:"tags"`
	Visibility        string   `json:"visibility"`          // private (default), circles, public
	ShareToCircleIDs  []string `json:"share_to_circle_ids"` // UUIDs
	ParentAudioID     string   `json:"parent_audio_id"`     // For threaded replies
}

// UpdateAudioItemRequest represents the request to update an audio item
type UpdateAudioItemRequest struct {
	Title            *string  `json:"title"`
	Description      *string  `json:"description"`
	Tags             []string `json:"tags"`
	Visibility       *string  `json:"visibility"`
	ShareToCircleIDs []string `json:"share_to_circle_ids"`
}

// UserResponse represents a user in responses
type UserResponse struct {
	ID          string `json:"id"`
	DisplayName string `json:"display_name"`
	AvatarURL   string `json:"avatar_url,omitempty"`
}

// AudioItemResponse represents the JSON response for an audio item
type AudioItemResponse struct {
	ID                string              `json:"id"`
	OwnerID           string              `json:"owner_id"`
	Owner             *UserResponse       `json:"owner,omitempty"`
	Visibility        string              `json:"visibility"`
	Title             string              `json:"title"`
	Description       string              `json:"description"`
	Kind              string              `json:"kind"`
	DurationSec       int                 `json:"duration_sec"`
	S3Key             string              `json:"s3_key,omitempty"`
	AudioURL          string              `json:"audio_url"`
	Waveform          json.RawMessage     `json:"waveform,omitempty"`
	Tags              []string            `json:"tags"`
	ShareToCircleIDs  []string            `json:"share_to_circle_ids"`
	ParentAudioID     *string             `json:"parent_audio_id,omitempty"`
	Stats             *AudioStatsResponse `json:"stats,omitempty"`
	UserState         *UserStateResponse  `json:"user_state,omitempty"`
	CreatedAt         string              `json:"created_at"`
	UpdatedAt         string              `json:"updated_at"`
}

type AudioStatsResponse struct {
	Likes  int64 `json:"likes"`
	Saves  int64 `json:"saves"`
	Plays  int64 `json:"plays"`
}

type UserStateResponse struct {
	Liked bool `json:"liked"`
	Saved bool `json:"saved"`
}

// CreateAudioItem creates a new audio item (POST /audio)
func CreateAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req CreateAudioItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	// Validation
	if req.S3Key == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "s3_key is required")
		return
	}
	if req.DurationSec <= 0 {
		WriteError(w, http.StatusBadRequest, "invalid_request", "duration_sec must be positive")
		return
	}
	if req.Kind != "micro" && req.Kind != "podcast_episode" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "kind must be 'micro' or 'podcast_episode'")
		return
	}

	// Default visibility to private (privacy by default)
	if req.Visibility == "" {
		req.Visibility = "private"
	}
	if req.Visibility != "private" && req.Visibility != "circles" && req.Visibility != "public" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "visibility must be 'private', 'circles', or 'public'")
		return
	}

	// Convert circle IDs to UUIDs
	var circleUUIDs []uuid.UUID
	for _, idStr := range req.ShareToCircleIDs {
		id, err := uuid.Parse(idStr)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID: "+idStr)
			return
		}
		circleUUIDs = append(circleUUIDs, id)
	}

	// TODO: Handle ParentAudioID for threaded replies when implementing
	_ = req.ParentAudioID

	// TODO: Create audio item using sqlc generated query
	// For now, return a mock response
	item := AudioItemResponse{
		ID:               uuid.New().String(),
		OwnerID:          userID.String(),
		Visibility:       req.Visibility,
		Title:            req.Title,
		Description:      req.Description,
		Kind:             req.Kind,
		DurationSec:      req.DurationSec,
		S3Key:            req.S3Key,
		AudioURL:         "https://cdn.moweton.com/" + req.S3Key, // TODO: Use CDN base from config
		Tags:             req.Tags,
		ShareToCircleIDs: req.ShareToCircleIDs,
		CreatedAt:        "2025-01-06T12:00:00Z",
		UpdatedAt:        "2025-01-06T12:00:00Z",
	}

	WriteJSON(w, http.StatusCreated, item)
}

// GetAudioItem retrieves an audio item by ID (GET /audio/:id)
func GetAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r) // May be nil for public items

	// TODO: Fetch from database using sqlc
	// TODO: Check permissions based on visibility
	// TODO: If private, only owner can access
	// TODO: If circles, only members of those circles can access
	// TODO: If public, anyone can access

	_ = audioUUID
	_ = userID

	// Mock response
	item := AudioItemResponse{
		ID:          audioID,
		OwnerID:     uuid.New().String(),
		Visibility:  "public",
		Title:       "Sample Audio",
		Description: "This is a sample audio item",
		Kind:        "micro",
		DurationSec: 45,
		AudioURL:    "https://cdn.moweton.com/sample.mp3",
		Tags:        []string{"technology", "startup"},
		Stats: &AudioStatsResponse{
			Likes: 42,
			Saves: 15,
			Plays: 120,
		},
		CreatedAt: "2025-01-06T12:00:00Z",
		UpdatedAt: "2025-01-06T12:00:00Z",
	}

	WriteJSON(w, http.StatusOK, item)
}

// ListMyAudioItems lists audio items for the authenticated user (GET /me/audio)
func ListMyAudioItems(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// Query params
	kind := r.URL.Query().Get("kind")
	visibility := r.URL.Query().Get("visibility")
	cursor := r.URL.Query().Get("cursor")
	limit := getIntQueryParam(r, "limit", 20)

	_ = kind
	_ = visibility
	_ = cursor
	_ = limit

	// TODO: Fetch from database using sqlc

	// Mock response
	response := map[string]interface{}{
		"items":       []AudioItemResponse{},
		"next_cursor": nil,
		"has_more":    false,
	}

	WriteJSON(w, http.StatusOK, response)
}

// UpdateAudioItem updates an audio item (PATCH /audio/:id)
func UpdateAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req UpdateAudioItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	// TODO: Check ownership
	// TODO: Update using sqlc

	_ = audioUUID

	// Mock response
	item := AudioItemResponse{
		ID:          audioID,
		OwnerID:     userID.String(),
		Visibility:  "public",
		Title:       "Updated Title",
		Description: "Updated description",
		Kind:        "micro",
		DurationSec: 45,
		AudioURL:    "https://cdn.moweton.com/sample.mp3",
		Tags:        req.Tags,
		CreatedAt:   "2025-01-06T12:00:00Z",
		UpdatedAt:   "2025-01-06T12:05:00Z",
	}

	WriteJSON(w, http.StatusOK, item)
}

// DeleteAudioItem deletes an audio item (DELETE /audio/:id)
func DeleteAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Check ownership
	// TODO: Delete using sqlc (will cascade to transcripts, summaries, clips, embeddings, etc.)

	_ = audioUUID

	w.WriteHeader(http.StatusNoContent)
}

// LikeAudioItem likes an audio item (POST /audio/:id/like)
func LikeAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Insert like using sqlc (ON CONFLICT DO NOTHING)

	_ = audioUUID

	w.WriteHeader(http.StatusNoContent)
}

// UnlikeAudioItem unlikes an audio item (DELETE /audio/:id/like)
func UnlikeAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Delete like using sqlc

	_ = audioUUID

	w.WriteHeader(http.StatusNoContent)
}

// SaveAudioItem saves (bookmarks) an audio item (POST /audio/:id/save)
func SaveAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Insert save using sqlc

	_ = audioUUID

	w.WriteHeader(http.StatusNoContent)
}

// UnsaveAudioItem unsaves an audio item (DELETE /audio/:id/save)
func UnsaveAudioItem(w http.ResponseWriter, r *http.Request, deps *app.App) {
	audioID := chi.URLParam(r, "id")
	audioUUID, err := uuid.Parse(audioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Delete save using sqlc

	_ = audioUUID

	w.WriteHeader(http.StatusNoContent)
}

// Helper to get user ID from context (set by auth middleware)
func getUserID(r *http.Request) uuid.UUID {
	userIDVal := r.Context().Value("user_id")
	if userIDVal == nil {
		return uuid.Nil
	}
	if uid, ok := userIDVal.(uuid.UUID); ok {
		return uid
	}
	return uuid.Nil
}

// Helper to get int query param with default
func getIntQueryParam(r *http.Request, key string, defaultVal int) int {
	val := r.URL.Query().Get(key)
	if val == "" {
		return defaultVal
	}
	// TODO: Parse int
	return defaultVal
}

// registerAudioItemRoutes registers routes for audio items
func registerAudioItemRoutes(r chi.Router, deps *app.App) {
	r.Route("/audio", func(r chi.Router) {
		r.Post("/", func(w http.ResponseWriter, req *http.Request) {
			CreateAudioItem(w, req, deps)
		})
		r.Get("/{id}", func(w http.ResponseWriter, req *http.Request) {
			GetAudioItem(w, req, deps)
		})
		r.Patch("/{id}", func(w http.ResponseWriter, req *http.Request) {
			UpdateAudioItem(w, req, deps)
		})
		r.Delete("/{id}", func(w http.ResponseWriter, req *http.Request) {
			DeleteAudioItem(w, req, deps)
		})

		// Social actions
		r.Post("/{id}/like", func(w http.ResponseWriter, req *http.Request) {
			LikeAudioItem(w, req, deps)
		})
		r.Delete("/{id}/like", func(w http.ResponseWriter, req *http.Request) {
			UnlikeAudioItem(w, req, deps)
		})
		r.Post("/{id}/save", func(w http.ResponseWriter, req *http.Request) {
			SaveAudioItem(w, req, deps)
		})
		r.Delete("/{id}/save", func(w http.ResponseWriter, req *http.Request) {
			UnsaveAudioItem(w, req, deps)
		})
	})

	r.Get("/me/audio", func(w http.ResponseWriter, req *http.Request) {
		ListMyAudioItems(w, req, deps)
	})
}


