package middleware

import (
	"database/sql"
	"net/http"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

// TryAuth attaches a user to the request context when a valid bearer token is
// provided, but does not require authentication for the request to proceed.
func TryAuth(deps *app.App, logger zerolog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := extractBearer(r.Header.Get("Authorization"))
			if token == "" {
				next.ServeHTTP(w, r)
				return
			}

			claims, err := deps.JWT.VerifyAccess(token)
			if err != nil {
				respondError(w, http.StatusUnauthorized, "unauthorized", "invalid token")
				return
			}

			userID, err := uuid.Parse(claims.UserID)
			if err != nil {
				respondError(w, http.StatusUnauthorized, "unauthorized", "invalid user id")
				return
			}

			user, err := fetchUser(r.Context(), deps.DB, userID)
			if err != nil {
				if err == sql.ErrNoRows {
					respondError(w, http.StatusUnauthorized, "unauthorized", "user not found")
					return
				}
				logger.Error().Err(err).Str("user_id", claims.UserID).Msg("optional auth failed to load user")
				respondError(w, http.StatusInternalServerError, "internal_error", "failed to load user")
				return
			}

			ctx := httpctx.WithUser(r.Context(), user)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
