package http

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

func allowRate(ctx context.Context, client *redis.Client, key string, limit int64, window time.Duration) (bool, time.Duration) {
	if client == nil || limit <= 0 {
		return true, 0
	}

	count, err := client.Incr(ctx, key).Result()
	if err != nil {
		return true, 0
	}
	if count == 1 {
		_ = client.Expire(ctx, key, window).Err()
	} else if count > limit {
		ttl, err := client.TTL(ctx, key).Result()
		if err != nil || ttl < 0 {
			ttl = window
		}
		return false, ttl
	}

	return true, 0
}
