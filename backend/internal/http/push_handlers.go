package http

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

var allowedPlatforms = map[string]struct{}{
	"ios":     {},
	"android": {},
	"web":     {},
}

type registerPushDeviceRequest struct {
	Token      string `json:"token"`
	Platform   string `json:"platform"`
	DeviceID   string `json:"device_id"`
	Locale     string `json:"locale"`
	AppVersion string `json:"app_version"`
}

func registerPushRoutes(r chi.Router, deps *app.App) {
	r.Post("/push/devices", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		var payload registerPushDeviceRequest
		if err := decodeJSON(req, &payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}

		if strings.TrimSpace(payload.Token) == "" {
			WriteError(w, http.StatusBadRequest, "invalid_request", "token is required")
			return
		}
		platform := strings.ToLower(strings.TrimSpace(payload.Platform))
		if _, ok := allowedPlatforms[platform]; !ok {
			WriteError(w, http.StatusBadRequest, "invalid_request", "unsupported platform")
			return
		}

		if err := upsertPushDevice(req.Context(), deps.DB, user.ID, payload); err != nil {
			WriteError(w, http.StatusInternalServerError, "push_register_failed", err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})

	r.Delete("/push/devices/{token}", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		token := chi.URLParam(req, "token")
		if strings.TrimSpace(token) == "" {
			WriteError(w, http.StatusBadRequest, "invalid_request", "token is required")
			return
		}
		if err := deletePushDevice(req.Context(), deps.DB, user.ID, token); err != nil {
			WriteError(w, http.StatusInternalServerError, "push_unregister_failed", err.Error())
			return
		}
		w.WriteHeader(http.StatusNoContent)
	})
}

func upsertPushDevice(ctx context.Context, db *sql.DB, userID uuid.UUID, payload registerPushDeviceRequest) error {
	const query = `
INSERT INTO push_devices (user_id, device_id, token, platform, locale, app_version, last_seen, updated_at)
VALUES ($1, NULLIF($2, ''), $3, $4, NULLIF($5, ''), NULLIF($6, ''), now(), now())
ON CONFLICT (token)
DO UPDATE SET
    user_id = EXCLUDED.user_id,
    device_id = EXCLUDED.device_id,
    platform = EXCLUDED.platform,
    locale = EXCLUDED.locale,
    app_version = EXCLUDED.app_version,
    last_seen = now(),
    updated_at = now();
`
	_, err := db.ExecContext(ctx, query,
		userID,
		payload.DeviceID,
		strings.TrimSpace(payload.Token),
		strings.ToLower(strings.TrimSpace(payload.Platform)),
		payload.Locale,
		payload.AppVersion,
	)
	return err
}

func deletePushDevice(ctx context.Context, db *sql.DB, userID uuid.UUID, token string) error {
	const query = `DELETE FROM push_devices WHERE user_id = $1 AND token = $2`
	_, err := db.ExecContext(ctx, query, userID, token)
	return err
}

func fetchFollowerPushTokens(ctx context.Context, db *sql.DB, hostID uuid.UUID) ([]string, error) {
	const query = `
SELECT DISTINCT pd.token
FROM user_follows uf
JOIN push_devices pd ON pd.user_id = uf.follower_id
WHERE uf.followee_id = $1
  AND pd.last_seen > NOW() - INTERVAL '90 days'
  AND pd.token <> ''
`
	rows, err := db.QueryContext(ctx, query, hostID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			return nil, err
		}
		tokens = append(tokens, token)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return tokens, nil
}
