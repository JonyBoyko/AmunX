package queue

import (
	"context"
	"errors"
	"strings"

	"github.com/redis/go-redis/v9"
)

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

// NewRedisStream wraps a go-redis client to implement Stream.
func NewRedisStream(client *redis.Client) Stream {
	return &redisStream{client: client}
}

type redisStream struct {
	client *redis.Client
}

func (r *redisStream) Enqueue(ctx context.Context, stream string, payload map[string]any) error {
	if stream == "" {
		return errors.New("stream name is required")
	}

	args := &redis.XAddArgs{
		Stream: stream,
		ID:     "*",
		Values: payload,
	}

	return r.client.XAdd(ctx, args).Err()
}

func (r *redisStream) Claim(ctx context.Context, stream, group, consumer string, batchSize int64) ([]Message, error) {
	if stream == "" || group == "" || consumer == "" {
		return nil, errors.New("stream, group, and consumer are required")
	}

	if err := r.ensureGroup(ctx, stream, group); err != nil {
		return nil, err
	}

	if batchSize <= 0 {
		batchSize = 1
	}

	args := &redis.XReadGroupArgs{
		Group:    group,
		Consumer: consumer,
		Streams:  []string{stream, ">"},
		Count:    batchSize,
		Block:    0,
	}

	streams, err := r.client.XReadGroup(ctx, args).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, nil
		}
		return nil, err
	}

	var messages []Message
	for _, st := range streams {
		for _, msg := range st.Messages {
			messages = append(messages, Message{
				ID:      msg.ID,
				Values:  msg.Values,
				Pending: false,
			})
		}
	}

	return messages, nil
}

func (r *redisStream) Ack(ctx context.Context, stream, group string, ids ...string) error {
	if stream == "" || group == "" || len(ids) == 0 {
		return errors.New("stream, group and ids are required")
	}
	return r.client.XAck(ctx, stream, group, ids...).Err()
}

func (r *redisStream) ensureGroup(ctx context.Context, stream, group string) error {
	err := r.client.XGroupCreateMkStream(ctx, stream, group, "0").Err()
	if err != nil {
		if strings.Contains(err.Error(), "BUSYGROUP") {
			return nil
		}
		return err
	}
	return nil
}
