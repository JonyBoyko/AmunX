package http

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/storage"
)

func registerDiagnosticsRoutes(r chi.Router, deps *app.App) {
	r.Get("/diagnostics/storage", func(w http.ResponseWriter, req *http.Request) {
		_, err := deps.Storage.PresignUpload(req.Context(), "diagnostics/ping", time.Second, "application/octet-stream")
		switch {
		case err == nil:
			writeJSON(w, http.StatusOK, map[string]any{"status": "ok"})
		case err == storage.ErrNotImplemented:
			writeJSON(w, http.StatusServiceUnavailable, map[string]any{"status": "disabled"})
		default:
			writeJSON(w, http.StatusServiceUnavailable, map[string]any{
				"status": "error",
				"error":  err.Error(),
			})
		}
	})

	r.Get("/diagnostics/queue", func(w http.ResponseWriter, req *http.Request) {
		err := deps.Queue.Enqueue(req.Context(), "diagnostics", map[string]any{
			"type": "ping",
		})
		if err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]any{
				"status": "error",
				"error":  err.Error(),
			})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"status": "ok"})
	})
}
