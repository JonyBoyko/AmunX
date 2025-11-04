package http

import (
	"context"
	"database/sql"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
)

func registerAuthRoutes(r chi.Router, deps *app.App, logger zerolog.Logger) {
	r.Route("/auth", func(ar chi.Router) {
		ar.Post("/magiclink", func(w http.ResponseWriter, req *http.Request) {
			var payload struct {
				Email string `json:"email"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}

			email := normalizeEmail(payload.Email)
			if email == "" {
				WriteError(w, http.StatusBadRequest, "invalid_email", "email is required")
				return
			}

			token, err := deps.MagicLinks.Sign(email)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "magic_link_error", "cannot generate token")
				return
			}

			cacheKey := magicLinkCacheKey(token)
			if err := deps.Redis.Set(req.Context(), cacheKey, email, deps.Config.MagicLinkTTL).Err(); err != nil {
				WriteError(w, http.StatusInternalServerError, "magic_link_error", "cannot persist token")
				return
			}

			logger.Info().
				Str("email", email).
				Str("magic_link_token", token).
				Msg("issued magic link token")

			WriteJSON(w, http.StatusAccepted, map[string]any{
				"status": "sent",
			})
		})

		ar.Post("/magiclink/verify", func(w http.ResponseWriter, req *http.Request) {
			var payload struct {
				Token string `json:"token"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}
			if payload.Token == "" {
				WriteError(w, http.StatusBadRequest, "invalid_token", "token is required")
				return
			}

			claims, err := deps.MagicLinks.Verify(payload.Token)
			if err != nil {
				WriteError(w, http.StatusUnauthorized, "invalid_token", "token verification failed")
				return
			}

			cacheKey := magicLinkCacheKey(payload.Token)
			storedEmail, err := deps.Redis.GetDel(req.Context(), cacheKey).Result()
			if err != nil {
				WriteError(w, http.StatusUnauthorized, "invalid_token", "token not found or already used")
				return
			}
			if normalizeEmail(storedEmail) != normalizeEmail(claims.Email) {
				WriteError(w, http.StatusUnauthorized, "invalid_token", "token mismatch")
				return
			}

			userID, plan, err := ensureUser(req.Context(), deps.DB, claims.Email)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "internal_error", "could not ensure user")
				return
			}

			accessToken, err := deps.JWT.IssueAccess(userID, plan)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "internal_error", "failed to issue access token")
				return
			}

			refreshToken, err := deps.JWT.IssueRefresh(userID)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "internal_error", "failed to issue refresh token")
				return
			}

			WriteJSON(w, http.StatusOK, map[string]any{
				"access_token":  accessToken,
				"refresh_token": refreshToken,
				"expires_in":    int(deps.Config.JWTAccessTTL / time.Second),
				"user_id":       userID,
				"plan":          plan,
			})
		})
	})
}

func ensureUser(ctx context.Context, db *sql.DB, email string) (string, string, error) {
	const upsertSQL = `
INSERT INTO users (email)
VALUES ($1)
ON CONFLICT (email)
DO UPDATE SET email = EXCLUDED.email
RETURNING id, COALESCE(plan, 'free') AS plan;
`
	var (
		id   uuid.UUID
		plan string
	)
	if err := db.QueryRowContext(ctx, upsertSQL, email).Scan(&id, &plan); err != nil {
		return "", "", err
	}
	return id.String(), plan, nil
}

func normalizeEmail(email string) string {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || !strings.Contains(email, "@") {
		return ""
	}
	return email
}

func magicLinkCacheKey(token string) string {
	return "magiclink:" + token
}
