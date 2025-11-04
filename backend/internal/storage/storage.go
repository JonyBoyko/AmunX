package storage

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client describes minimal methods our app needs from object storage.
type Client interface {
	PutObject(ctx context.Context, key string, body io.Reader, metadata map[string]string) (string, error)
	PresignUpload(ctx context.Context, key string, ttl time.Duration, contentType string) (string, error)
}

// PresignedUpload holds metadata for generated upload URLs.
type PresignedUpload struct {
	URL     string
	Method  string
	Headers http.Header
}

// ErrNotImplemented signals functionality not yet implemented.
var ErrNotImplemented = fmt.Errorf("not implemented")

