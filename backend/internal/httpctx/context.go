package httpctx

import (
	"context"

	"github.com/google/uuid"
)

type contextKey string

const userKey contextKey = "currentUser"

// User represents an authenticated user attached to a request.
type User struct {
	ID           uuid.UUID
	Handle       *string
	Email        string
	DisplayName  *string
	Avatar       *string
	IsAnon       bool
	Plan         string
	Shadowbanned bool
}

// WithUser stores the user in the provided context.
func WithUser(ctx context.Context, user User) context.Context {
	return context.WithValue(ctx, userKey, user)
}

// UserFromContext retrieves the user from context.
func UserFromContext(ctx context.Context) (User, bool) {
	val := ctx.Value(userKey)
	if val == nil {
		return User{}, false
	}
	user, ok := val.(User)
	return user, ok
}
