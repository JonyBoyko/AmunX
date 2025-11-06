package http

import (
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// PresignUploadRequest represents the request for presigned upload URL
type PresignUploadRequest struct {
	MIME     string `json:"mime"`
	Filename string `json:"filename"`
}

// PresignUploadResponse represents the presigned upload response
type PresignUploadResponse struct {
	URL       string            `json:"url"`
	Fields    map[string]string `json:"fields"`
	S3Key     string            `json:"s3_key"`
	ExpiresAt string            `json:"expires_at"`
}

// RequestPresignedUpload generates a presigned URL for S3 upload (POST /uploads/presign)
func RequestPresignedUpload(w http.ResponseWriter, r *http.Request, deps *app.App) {
	userID := getUserID(r)
	if userID == uuid.Nil {
		WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
		return
	}

	var req PresignUploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_request", "invalid_request")
		return
	}

	// Validate MIME type
	if req.MIME == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "mime is required")
		return
	}

	// Validate MIME type is audio
	if !isAudioMIME(req.MIME) {
		WriteError(w, http.StatusBadRequest, "invalid_request", "only audio files are supported")
		return
	}

	// Generate S3 key: uploads/{user_id}/{uuid}.{ext}
	ext := getExtensionFromMIME(req.MIME)
	if req.Filename != "" {
		fileExt := filepath.Ext(req.Filename)
		if fileExt != "" {
			ext = fileExt
		}
	}
	s3Key := fmt.Sprintf("uploads/%s/%s%s", userID.String(), uuid.New().String(), ext)

	// TODO: Generate presigned POST URL using AWS SDK or MinIO SDK
	// For now, return mock response

	// Expiration: 15 minutes
	expiresAt := time.Now().Add(15 * time.Minute)

	response := PresignUploadResponse{
		URL: "https://s3.example.com/amunx-bucket",
		Fields: map[string]string{
			"key":                         s3Key,
			"Content-Type":                req.MIME,
			"acl":                         "private",
			"x-amz-algorithm":             "AWS4-HMAC-SHA256",
			"x-amz-credential":            "...",
			"x-amz-date":                  time.Now().Format("20060102T150405Z"),
			"policy":                      "base64-encoded-policy",
			"x-amz-signature":             "signature-here",
		},
		S3Key:     s3Key,
		ExpiresAt: expiresAt.Format(time.RFC3339),
	}

	WriteJSON(w, http.StatusOK, response)
}

// isAudioMIME checks if the MIME type is audio
func isAudioMIME(mime string) bool {
	audioMIMEs := []string{
		"audio/mpeg",
		"audio/mp3",
		"audio/mp4",
		"audio/m4a",
		"audio/wav",
		"audio/x-wav",
		"audio/webm",
		"audio/ogg",
		"audio/flac",
		"audio/aac",
	}
	for _, m := range audioMIMEs {
		if mime == m {
			return true
		}
	}
	return false
}

// getExtensionFromMIME returns file extension for MIME type
func getExtensionFromMIME(mime string) string {
	extensions := map[string]string{
		"audio/mpeg":  ".mp3",
		"audio/mp3":   ".mp3",
		"audio/mp4":   ".mp4",
		"audio/m4a":   ".m4a",
		"audio/wav":   ".wav",
		"audio/x-wav": ".wav",
		"audio/webm":  ".webm",
		"audio/ogg":   ".ogg",
		"audio/flac":  ".flac",
		"audio/aac":   ".aac",
	}
	if ext, ok := extensions[mime]; ok {
		return ext
	}
	return ".mp3" // default
}

// registerUploadRoutes registers routes for uploads
func registerUploadRoutes(r chi.Router, deps *app.App) {
	r.Post("/uploads/presign", func(w http.ResponseWriter, req *http.Request) {
		RequestPresignedUpload(w, req, deps)
	})
}


