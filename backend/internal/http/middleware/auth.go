package middleware

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

func Auth(deps *app.App, logger zerolog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := extractBearer(r.Header.Get("Authorization"))
			if token == "" {
				respondError(w, http.StatusUnauthorized, "unauthorized", "missing bearer token")
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
				logger.Error().Err(err).Str("user_id", claims.UserID).Msg("failed to load user")
				respondError(w, http.StatusInternalServerError, "internal_error", "failed to load user")
				return
			}

			ctx := httpctx.WithUser(r.Context(), user)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func extractBearer(header string) string {
	if header == "" {
		return ""
	}
	if !strings.HasPrefix(strings.ToLower(header), "bearer ") {
		return ""
	}
	return strings.TrimSpace(header[7:])
}

func fetchUser(ctx context.Context, db *sql.DB, id uuid.UUID) (httpctx.User, error) {
	const query = `
SELECT id, handle, email, display_name, avatar, is_anon, plan
FROM users
WHERE id = $1;
`
	var (
		user        httpctx.User
		handle      sql.NullString
		displayName sql.NullString
		avatar      sql.NullString
	)

	err := db.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&handle,
		&user.Email,
		&displayName,
		&avatar,
		&user.IsAnon,
		&user.Plan,
	)
	if err != nil {
		return httpctx.User{}, err
	}

	if handle.Valid {
		user.Handle = &handle.String
	}
	if displayName.Valid {
		user.DisplayName = &displayName.String
	}
	if avatar.Valid {
		user.Avatar = &avatar.String
	}

	return user, nil
}

func respondError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"error":             code,
		"error_description": message,
	})
}
