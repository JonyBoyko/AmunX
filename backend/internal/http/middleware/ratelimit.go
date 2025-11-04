package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// RateLimiter implements a simple fixed-window rate limiter backed by Redis.
type RateLimiter struct {
	client *redis.Client
	window time.Duration
	max    int64
}

// NewRateLimiter constructs a RateLimiter.
func NewRateLimiter(client *redis.Client, window time.Duration, max int) *RateLimiter {
	return &RateLimiter{
		client: client,
		window: window,
		max:    int64(max),
	}
}

// Handler returns a middleware that enforces the limiter per remote identity.
func (r *RateLimiter) Handler() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			if r == nil || r.client == nil || r.max <= 0 {
				next.ServeHTTP(w, req)
				return
			}

			key := r.buildKey(req)

			allowed, ttl, err := r.allow(req.Context(), key)
			if err != nil {
				// Fail open on Redis issues.
				next.ServeHTTP(w, req)
				return
			}
			if !allowed {
				if ttl > 0 {
					w.Header().Set("Retry-After", fmt.Sprintf("%.f", ttl.Seconds()))
				}
				http.Error(w, http.StatusText(http.StatusTooManyRequests), http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, req)
		})
	}
}

func (r *RateLimiter) buildKey(req *http.Request) string {
	identity := req.Header.Get("X-Forwarded-For")
	if identity != "" {
		parts := strings.Split(identity, ",")
		identity = strings.TrimSpace(parts[0])
	}
	if identity == "" {
		identity = req.RemoteAddr
	}
	return fmt.Sprintf("rl:%s", identity)
}

func (r *RateLimiter) allow(ctx context.Context, key string) (bool, time.Duration, error) {
	count, err := r.client.Incr(ctx, key).Result()
	if err != nil {
		return true, 0, err
	}

	if count == 1 {
		if err := r.client.Expire(ctx, key, r.window).Err(); err != nil {
			return true, 0, err
		}
	}

	if count > r.max {
		ttl, err := r.client.TTL(ctx, key).Result()
		if err != nil {
			return false, 0, err
		}
		if ttl < 0 {
			ttl = 0
		}
		return false, ttl, nil
	}

	return true, 0, nil
}
