package queue

import "context"

// Stream defines the minimal Redis Stream interactions used by workers.
type Stream interface {
	Enqueue(ctx context.Context, stream string, payload map[string]any) error
	Claim(ctx context.Context, stream, group, consumer string, batchSize int64) ([]Message, error)
	Ack(ctx context.Context, stream, group string, ids ...string) error
}

// Message represents a single queue message.
type Message struct {
	ID      string
	Values  map[string]any
	Pending bool
}

