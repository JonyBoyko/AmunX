package middleware

import (
	"net/http"
	"time"

	"github.com/rs/zerolog"
)

// Logger logs basic request metadata and duration.
func Logger(logger zerolog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			ww := &responseWriter{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(ww, r)

			duration := time.Since(start)
			evt := logger.Info().
				Str("method", r.Method).
				Str("path", r.URL.Path).
				Str("query", r.URL.RawQuery).
				Str("remote_addr", r.RemoteAddr).
				Str("user_agent", r.UserAgent()).
				Int("status", ww.status).
				Str("request_id", r.Header.Get("X-Request-ID")).
				Dur("duration", duration)

			// Log errors with more detail
			if ww.status >= 400 {
				evt = evt.Str("error_type", "http_error")
				if ww.status >= 500 {
					logger.Error().
						Str("method", r.Method).
						Str("path", r.URL.Path).
						Int("status", ww.status).
						Dur("duration", duration).
						Msg("request failed")
				} else {
					logger.Warn().
						Str("method", r.Method).
						Str("path", r.URL.Path).
						Int("status", ww.status).
						Dur("duration", duration).
						Msg("request client error")
				}
			}

			evt.Msg("request")
		})
	}
}

type responseWriter struct {
	http.ResponseWriter
	status int
}

func (w *responseWriter) WriteHeader(code int) {
	w.status = code
	w.ResponseWriter.WriteHeader(code)
}

