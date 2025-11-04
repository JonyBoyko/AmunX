package middleware

import (
	"compress/gzip"
	"net/http"
	"strings"
)

// Gzip compresses responses when the client accepts gzip encoding.
func Gzip(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
			next.ServeHTTP(w, r)
			return
		}

		gzw := gzip.NewWriter(w)
		defer gzw.Close()

		gzWriter := &gzipResponseWriter{
			ResponseWriter: w,
			writer:         gzw,
		}
		w.Header().Set("Content-Encoding", "gzip")
		next.ServeHTTP(gzWriter, r)
	})
}

type gzipResponseWriter struct {
	http.ResponseWriter
	writer *gzip.Writer
}

func (w *gzipResponseWriter) Write(b []byte) (int, error) {
	return w.writer.Write(b)
}

func (w *gzipResponseWriter) WriteHeader(statusCode int) {
	w.ResponseWriter.WriteHeader(statusCode)
}

func (w *gzipResponseWriter) Header() http.Header {
	return w.ResponseWriter.Header()
}

