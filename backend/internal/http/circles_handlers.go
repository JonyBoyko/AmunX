package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// CreateCircleRequest represents the request to create a circle
type CreateCircleRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	IsLocal     bool   `json:"is_local"`
	City        string `json:"city"`
	Country     string `json:"country"`
}

// CircleResponse represents a circle
type CircleResponse struct {
	ID           string        `json:"id"`
	OwnerID      string        `json:"owner_id"`
	Owner        *UserResponse `json:"owner,omitempty"`
	Name         string        `json:"name"`
	Description  string        `json:"description"`
	IsLocal      bool          `json:"is_local"`
	City         string        `json:"city"`
	Country      string        `json:"country"`
	MemberCount  int           `json:"member_count"`
	UserRole     string        `json:"user_role,omitempty"` // owner, moderator, member, or empty if not a member
	CreatedAt    string        `json:"created_at"`
}

// CreateCirclePostRequest represents posting audio to a circle
type CreateCirclePostRequest struct {
	AudioID     string `json:"audio_id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

// CreateCircleReplyRequest represents a threaded reply in a circle
type CreateCircleReplyRequest struct {
	ParentAudioID string `json:"parent_audio_id"`
	S3Key         string `json:"s3_key"`
	DurationSec   int    `json:"duration_sec"`
	Title         string `json:"title"`
}

// ModerateCircleRequest represents a moderation action
type ModerateCircleRequest struct {
	TargetUserID  string `json:"target_user_id"`
	TargetAudioID string `json:"target_audio_id,omitempty"`
	Action        string `json:"action"` // remove_member, delete_post, promote_moderator, demote_moderator
}

// CreateCircle creates a new Smart Circle (POST /circles)
func CreateCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req CreateCircleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	if req.Name == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "name is required")
		return
	}

	// TODO: Create circle using sqlc
	// TODO: Automatically add creator as owner in circle_members

	circle := CircleResponse{
		ID:          uuid.New().String(),
		OwnerID:     userID.String(),
		Name:        req.Name,
		Description: req.Description,
		IsLocal:     req.IsLocal,
		City:        req.City,
		Country:     req.Country,
		MemberCount: 1,
		UserRole:    "owner",
		CreatedAt:   "2025-01-06T12:00:00Z",
	}

	WriteJSON(w, http.StatusCreated, circle)
}

// GetCircle retrieves a circle by ID (GET /circles/:id)
func GetCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r) // May be nil for public viewing

	// TODO: Fetch circle from database
	// TODO: Check if user is a member and get their role
	// TODO: Get member count

	_ = circleUUID
	_ = userID

	circle := CircleResponse{
		ID:          circleID,
		OwnerID:     uuid.New().String(),
		Name:        "Warsaw Tech Community",
		Description: "Voice discussions for Warsaw tech folks",
		IsLocal:     true,
		City:        "Warsaw",
		Country:     "Poland",
		MemberCount: 42,
		UserRole:    "member",
		CreatedAt:   "2025-01-06T12:00:00Z",
	}

	WriteJSON(w, http.StatusOK, circle)
}

// ListCircles lists all circles (GET /circles)
func ListCircles(w http.ResponseWriter, r *http.Request, deps *app.App) {
	city := r.URL.Query().Get("city")
	limit := getIntQueryParam(r, "limit", 20)
	offset := getIntQueryParam(r, "offset", 0)

	_ = city
	_ = limit
	_ = offset

	// TODO: Fetch circles from database with filters

	response := map[string]interface{}{
		"circles":  []CircleResponse{},
		"has_more": false,
	}

	WriteJSON(w, http.StatusOK, response)
}

// JoinCircle joins a circle (POST /circles/:id/join)
func JoinCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Add user to circle_members with role='member'
	// TODO: Use ON CONFLICT DO NOTHING to handle duplicate joins

	_ = circleUUID

	response := map[string]interface{}{
		"circle_id": circleID,
		"user_id":   userID.String(),
		"role":      "member",
		"joined_at": "2025-01-06T12:00:00Z",
	}

	WriteJSON(w, http.StatusOK, response)
}

// LeaveCircle leaves a circle (POST /circles/:id/leave)
func LeaveCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// TODO: Remove from circle_members
	// TODO: Prevent owner from leaving (or transfer ownership first)

	_ = circleUUID

	w.WriteHeader(http.StatusNoContent)
}

// GetCircleFeed gets the voice thread feed for a circle (GET /circles/:id/feed)
func GetCircleFeed(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	cursor := r.URL.Query().Get("cursor")
	limit := getIntQueryParam(r, "limit", 20)

	// TODO: Check if user is a member
	// TODO: Fetch audio_items where circleID is in share_to_circle_ids
	// TODO: Include reply counts (count where parent_audio_id = item.id)

	_ = circleUUID
	_ = cursor
	_ = limit

	response := map[string]interface{}{
		"posts":       []AudioItemResponse{},
		"next_cursor": nil,
		"has_more":    false,
	}

	WriteJSON(w, http.StatusOK, response)
}

// PostToCircle posts an audio item to a circle (POST /circles/:id/posts)
func PostToCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req CreateCirclePostRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	if req.AudioID == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "audio_id is required")
		return
	}

	// TODO: Check if user is a member
	// TODO: Update audio_item to add circleID to share_to_circle_ids
	// TODO: Or set visibility='circles' if not already

	_ = circleUUID

	w.WriteHeader(http.StatusCreated)
}

// ReplyToCirclePost creates a threaded reply in a circle (POST /circles/:id/replies)
func ReplyToCirclePost(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req CreateCircleReplyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	if req.ParentAudioID == "" || req.S3Key == "" || req.DurationSec <= 0 {
		WriteError(w, http.StatusBadRequest, "invalid_request", "parent_audio_id, s3_key, and duration_sec are required")
		return
	}

	// TODO: Check if user is a member
	// TODO: Verify parent audio exists and is in this circle
	// TODO: Create new audio_item with parent_audio_id set

	_ = circleUUID

	reply := AudioItemResponse{
		ID:            uuid.New().String(),
		OwnerID:       userID.String(),
		Visibility:    "circles",
		Title:         req.Title,
		Kind:          "micro",
		DurationSec:   req.DurationSec,
		S3Key:         req.S3Key,
		AudioURL:      "https://cdn.amunx.com/" + req.S3Key,
		ParentAudioID: &req.ParentAudioID,
		CreatedAt:     "2025-01-06T12:10:00Z",
	}

	WriteJSON(w, http.StatusCreated, reply)
}

// ModerateCircle performs moderation action in a circle (POST /circles/:id/moderate)
func ModerateCircle(w http.ResponseWriter, r *http.Request, deps *app.App) {
	circleID := chi.URLParam(r, "id")
	circleUUID, err := uuid.Parse(circleID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid circle ID")
		return
	}

	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req ModerateCircleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	// TODO: Check if user is owner or moderator
	// TODO: Execute action based on req.Action

	_ = circleUUID

	switch req.Action {
	case "remove_member":
		// TODO: Remove user from circle_members
	case "delete_post":
		// TODO: Delete audio_item (requires target_audio_id)
	case "promote_moderator":
		// TODO: Update circle_member role to 'moderator'
	case "demote_moderator":
		// TODO: Update circle_member role to 'member'
	default:
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid action")
		return
	}

	WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// registerCircleRoutes registers routes for Smart Circles
func registerCircleRoutes(r chi.Router, deps *app.App) {
	r.Route("/circles", func(r chi.Router) {
		r.Get("/", func(w http.ResponseWriter, req *http.Request) {
			ListCircles(w, req, deps)
		})
		r.Post("/", func(w http.ResponseWriter, req *http.Request) {
			CreateCircle(w, req, deps)
		})
		r.Get("/{id}", func(w http.ResponseWriter, req *http.Request) {
			GetCircle(w, req, deps)
		})

		// Membership
		r.Post("/{id}/join", func(w http.ResponseWriter, req *http.Request) {
			JoinCircle(w, req, deps)
		})
		r.Post("/{id}/leave", func(w http.ResponseWriter, req *http.Request) {
			LeaveCircle(w, req, deps)
		})

		// Feed and posts
		r.Get("/{id}/feed", func(w http.ResponseWriter, req *http.Request) {
			GetCircleFeed(w, req, deps)
		})
		r.Post("/{id}/posts", func(w http.ResponseWriter, req *http.Request) {
			PostToCircle(w, req, deps)
		})
		r.Post("/{id}/replies", func(w http.ResponseWriter, req *http.Request) {
			ReplyToCirclePost(w, req, deps)
		})

		// Moderation
		r.Post("/{id}/moderate", func(w http.ResponseWriter, req *http.Request) {
			ModerateCircle(w, req, deps)
		})
	})
}


