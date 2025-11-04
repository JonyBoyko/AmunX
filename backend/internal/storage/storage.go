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
	PresignUpload(ctx context.Context, key string, ttl time.Duration, contentType string) (PresignedUpload, error)
}

// PresignedUpload holds metadata for generated upload URLs.
type PresignedUpload struct {
	URL     string
	Method  string
	Headers http.Header
}

// ErrNotImplemented signals functionality not yet implemented.
var ErrNotImplemented = fmt.Errorf("not implemented")

// ErrIncompleteConfig indicates required configuration is missing.
var ErrIncompleteConfig = fmt.Errorf("storage configuration incomplete")

// NewNoopClient returns a storage client that always fails with ErrNotImplemented.
func NewNoopClient() Client {
	return noopClient{}
}

type noopClient struct{}

func (noopClient) PutObject(context.Context, string, io.Reader, map[string]string) (string, error) {
	return "", ErrNotImplemented
}

func (noopClient) PresignUpload(context.Context, string, time.Duration, string) (PresignedUpload, error) {
	return PresignedUpload{}, ErrNotImplemented
}
