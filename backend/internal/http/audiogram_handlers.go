package http

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// GenerateAudiogramRequest represents the request to generate an audiogram
type GenerateAudiogramRequest struct {
	AudioID      string  `json:"audio_id"`
	ClipID       *string `json:"clip_id"`
	StartSec     *int    `json:"start_sec"`
	EndSec       *int    `json:"end_sec"`
	StylePreset  string  `json:"style_preset"` // clean, waveform, subtitle
	SubtitleLang string  `json:"subtitle_lang"`
	CoverText    string  `json:"cover_text"`
}

// AudiogramJobResponse represents the audiogram job response
type AudiogramJobResponse struct {
	JobID  string `json:"job_id"`
	Status string `json:"status"` // queued, running, succeeded, failed
	S3Key  string `json:"s3_key,omitempty"`
	Error  string `json:"error,omitempty"`
}

// GenerateAudiogramHandler creates an audiogram generation job (POST /audiogram)
func GenerateAudiogramHandler(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// Check feature flag
	if !deps.Config.FeatureAudiogramExport {
		WriteError(w, http.StatusNotImplemented, "feature_disabled", "audiogram export is not enabled")
		return
	}

	var req GenerateAudiogramRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid request body")
		return
	}

	// Validate
	if req.AudioID == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "audio_id is required")
		return
	}

	audioUUID, err := uuid.Parse(req.AudioID)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid audio_id")
		return
	}

	// Default style
	if req.StylePreset == "" {
		req.StylePreset = "subtitle"
	}

	// Validate style
	validStyles := map[string]bool{"clean": true, "waveform": true, "subtitle": true}
	if !validStyles[req.StylePreset] {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid style_preset")
		return
	}

	_ = audioUUID

	// TODO: Check audio ownership or public access
	// TODO: Queue job to Redis for worker
	// TODO: Store job in database or Redis

	jobID := uuid.New().String()

	// Mock response
	response := AudiogramJobResponse{
		JobID:  jobID,
		Status: "queued",
	}

	WriteJSON(w, http.StatusOK, response)
}

// GetAudiogramJobHandler gets audiogram job status (GET /audiogram/jobs/:id)
func GetAudiogramJobHandler(w http.ResponseWriter, r *http.Request, deps *app.App) {
	jobID := chi.URLParam(r, "id")
	if jobID == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "job_id required")
		return
	}

	// TODO: Fetch job status from Redis or database

	// Mock response
	response := AudiogramJobResponse{
		JobID:  jobID,
		Status: "succeeded",
		S3Key:  "audiograms/" + jobID + ".mp4",
	}

	WriteJSON(w, http.StatusOK, response)
}

// CrosspostYouTubeHandler uploads audiogram to YouTube (POST /crosspost/youtube)
func CrosspostYouTubeHandler(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	// Check feature flag
	if !deps.Config.FeatureCrosspostYoutube {
		WriteError(w, http.StatusNotImplemented, "feature_disabled", "youtube crosspost is not enabled")
		return
	}

	// TODO: Implement YouTube OAuth upload
	WriteJSON(w, http.StatusNotImplemented, map[string]string{
		"status":  "not_implemented",
		"message": "YouTube OAuth upload coming in v2",
	})
}

// registerAudiogramRoutes registers routes for audiogram
func registerAudiogramRoutes(r chi.Router, deps *app.App) {
	r.Post("/audiogram", func(w http.ResponseWriter, req *http.Request) {
		GenerateAudiogramHandler(w, req, deps)
	})

	r.Get("/audiogram/jobs/{id}", func(w http.ResponseWriter, req *http.Request) {
		GetAudiogramJobHandler(w, req, deps)
	})

	r.Post("/crosspost/youtube", func(w http.ResponseWriter, req *http.Request) {
		CrosspostYouTubeHandler(w, req, deps)
	})
}

