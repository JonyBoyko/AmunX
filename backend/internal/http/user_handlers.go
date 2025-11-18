package http

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

func registerUserRoutes(r chi.Router, deps *app.App) {
	r.Get("/me", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"id":           user.ID,
			"handle":       user.Handle,
			"email":        user.Email,
			"display_name": user.DisplayName,
			"avatar":       user.Avatar,
			"is_anon":      user.IsAnon,
			"plan":         user.Plan,
			"shadowbanned": user.Shadowbanned,
		})
	})

	r.Get("/me/profile", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		payloads, err := listUserProfiles(req.Context(), deps.DB, []uuid.UUID{user.ID}, nil)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "profile_lookup_failed", err.Error())
			return
		}
		if len(payloads) == 0 {
			WriteError(w, http.StatusNotFound, "profile_not_found", "profile not found")
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{
			"profile": payloads[0],
		})
	})

	r.Patch("/me/profile", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		var updateReq updateProfileRequest
		if err := decodeJSON(req, &updateReq); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		if updateReq.Bio == nil && updateReq.SocialLinks == nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", "provide at least one field to update")
			return
		}

		if err := applyProfileUpdate(req.Context(), deps.DB, user.ID, updateReq); err != nil {
			WriteError(w, http.StatusInternalServerError, "profile_update_failed", err.Error())
			return
		}

		payloads, err := listUserProfiles(req.Context(), deps.DB, []uuid.UUID{user.ID}, nil)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "profile_lookup_failed", err.Error())
			return
		}
		if len(payloads) == 0 {
			WriteError(w, http.StatusNotFound, "profile_not_found", "profile not found")
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{
			"profile": payloads[0],
		})
	})
}

type updateProfileRequest struct {
	Bio         *string           `json:"bio"`
	SocialLinks map[string]string `json:"social_links"`
}

func applyProfileUpdate(ctx context.Context, db *sql.DB, userID uuid.UUID, req updateProfileRequest) error {
	var (
		currentBio    sql.NullString
		currentAvatar sql.NullString
		settingsRaw   []byte
	)
	if err := db.QueryRowContext(ctx, `SELECT bio, avatar_url, settings FROM profiles WHERE user_id = $1`, userID).
		Scan(&currentBio, &currentAvatar, &settingsRaw); err != nil && err != sql.ErrNoRows {
		return err
	}

	settings := map[string]any{}
	if len(settingsRaw) > 0 {
		if err := json.Unmarshal(settingsRaw, &settings); err != nil {
			settings = map[string]any{}
		}
	}

	var bioValue *string
	if currentBio.Valid {
		bioValue = stringPtr(currentBio.String)
	}
	if req.Bio != nil {
		sanitized := sanitizeBio(*req.Bio)
		if sanitized == "" {
			bioValue = nil
		} else {
			bioValue = stringPtr(sanitized)
		}
	}

	var avatarValue *string
	if currentAvatar.Valid {
		avatarValue = stringPtr(currentAvatar.String)
	}

	if req.SocialLinks != nil {
		if sanitized := sanitizeSocialLinks(req.SocialLinks); len(sanitized) == 0 {
			delete(settings, "social_links")
		} else {
			settings["social_links"] = sanitized
		}
	}

	settingsJSON, err := json.Marshal(settings)
	if err != nil {
		return err
	}

	_, err = db.ExecContext(ctx, `
INSERT INTO profiles (user_id, bio, avatar_url, settings)
VALUES ($1, $2, $3, $4)
ON CONFLICT (user_id) DO UPDATE
   SET bio = EXCLUDED.bio,
       avatar_url = EXCLUDED.avatar_url,
       settings = EXCLUDED.settings,
       updated_at = now()
`, userID, nullableString(bioValue), nullableString(avatarValue), settingsJSON)
	return err
}

func sanitizeBio(input string) string {
	trimmed := strings.TrimSpace(input)
	if len(trimmed) > 480 {
		return trimmed[:480]
	}
	return trimmed
}

var allowedSocialProviders = map[string]struct{}{
	"twitter":   {},
	"instagram": {},
	"linkedin":  {},
	"youtube":   {},
	"website":   {},
	"tiktok":    {},
}

func sanitizeSocialLinks(input map[string]string) map[string]string {
	if len(input) == 0 {
		return map[string]string{}
	}
	sanitized := make(map[string]string)
	for key, raw := range input {
		normalizedKey := strings.ToLower(strings.TrimSpace(key))
		if normalizedKey == "" {
			continue
		}
		if _, ok := allowedSocialProviders[normalizedKey]; !ok {
			continue
		}
		value := strings.TrimSpace(raw)
		if value == "" {
			continue
		}
		if len(value) > 200 {
			value = value[:200]
		}
		sanitized[normalizedKey] = value
		if len(sanitized) >= 5 {
			break
		}
	}
	return sanitized
}

func stringPtr(value string) *string {
	v := value
	return &v
}

func nullableString(value *string) interface{} {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}
