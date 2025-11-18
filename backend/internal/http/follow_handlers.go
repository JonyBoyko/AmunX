package http

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
	mw "github.com/amunx/backend/internal/http/middleware"
	"github.com/amunx/backend/internal/httpctx"
)

var errFollowSelf = errors.New("cannot follow yourself")

type authorProfilePayload struct {
	ID          string            `json:"id"`
	DisplayName string            `json:"display_name"`
	Handle      string            `json:"handle"`
	Bio         *string           `json:"bio,omitempty"`
	Avatar      *string           `json:"avatar,omitempty"`
	Followers   int               `json:"followers"`
	Following   int               `json:"following"`
	Posts       int               `json:"posts"`
	SocialLinks map[string]string `json:"social_links,omitempty"`
	IsFollowing bool              `json:"is_following"`
}

func registerPublicUserRoutes(r chi.Router, deps *app.App, logger zerolog.Logger) {
	withOptionalAuth := mw.TryAuth(deps, logger)

	r.With(withOptionalAuth).Get("/users/profiles", func(w http.ResponseWriter, req *http.Request) {
		rawIDs := strings.TrimSpace(req.URL.Query().Get("ids"))
		if rawIDs == "" {
			WriteError(w, http.StatusBadRequest, "missing_ids", "ids query parameter is required")
			return
		}

		idTokens := strings.Split(rawIDs, ",")
		if len(idTokens) > 64 {
			WriteError(w, http.StatusBadRequest, "too_many_ids", "maximum 64 ids supported")
			return
		}

		var ids []uuid.UUID
		for _, token := range idTokens {
			if token = strings.TrimSpace(token); token == "" {
				continue
			}
			parsed, err := uuid.Parse(token)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_user_id", "ids must be valid UUIDs")
				return
			}
			ids = append(ids, parsed)
		}
		if len(ids) == 0 {
			WriteError(w, http.StatusBadRequest, "missing_ids", "ids query parameter is required")
			return
		}

		var requester *uuid.UUID
		if user, ok := httpctx.UserFromContext(req.Context()); ok {
			requester = &user.ID
		}

		profiles, err := listUserProfiles(req.Context(), deps.DB, ids, requester)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "profiles_lookup_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"profiles": profiles,
		})
	})
}

func registerFollowRoutes(r chi.Router, deps *app.App) {
	r.Post("/users/{id}/follow", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		targetID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_user_id", err.Error())
			return
		}

		if err := followUser(req.Context(), deps.DB, currentUser.ID, targetID); err != nil {
			switch {
			case errors.Is(err, errFollowSelf):
				WriteError(w, http.StatusBadRequest, "invalid_follow", err.Error())
				return
			case errors.Is(err, sql.ErrNoRows):
				WriteError(w, http.StatusNotFound, "user_not_found", "user not found")
				return
			default:
				WriteError(w, http.StatusInternalServerError, "follow_failed", err.Error())
				return
			}
		}

		count, err := countFollowers(req.Context(), deps.DB, targetID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "followers_count_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"status":    "followed",
			"followers": count,
		})
	})

	r.Delete("/users/{id}/follow", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		targetID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_user_id", err.Error())
			return
		}

		if err := unfollowUser(req.Context(), deps.DB, currentUser.ID, targetID); err != nil {
			switch {
			case errors.Is(err, errFollowSelf):
				WriteError(w, http.StatusBadRequest, "invalid_follow", err.Error())
				return
			case errors.Is(err, sql.ErrNoRows):
				WriteError(w, http.StatusNotFound, "user_not_found", "user not found")
				return
			default:
				WriteError(w, http.StatusInternalServerError, "unfollow_failed", err.Error())
				return
			}
		}

		count, err := countFollowers(req.Context(), deps.DB, targetID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "followers_count_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"status":    "unfollowed",
			"followers": count,
		})
	})
}

func followUser(ctx context.Context, db *sql.DB, followerID, followeeID uuid.UUID) error {
	if followerID == followeeID {
		return errFollowSelf
	}
	if exists, err := userExists(ctx, db, followeeID); err != nil {
		return err
	} else if !exists {
		return sql.ErrNoRows
	}

	_, err := db.ExecContext(ctx, `
INSERT INTO user_follows (follower_id, followee_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;
`, followerID, followeeID)
	return err
}

func unfollowUser(ctx context.Context, db *sql.DB, followerID, followeeID uuid.UUID) error {
	if followerID == followeeID {
		return errFollowSelf
	}
	if exists, err := userExists(ctx, db, followeeID); err != nil {
		return err
	} else if !exists {
		return sql.ErrNoRows
	}

	_, err := db.ExecContext(ctx, `DELETE FROM user_follows WHERE follower_id = $1 AND followee_id = $2`, followerID, followeeID)
	return err
}

func countFollowers(ctx context.Context, db *sql.DB, userID uuid.UUID) (int, error) {
	var count int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM user_follows WHERE followee_id = $1`, userID).Scan(&count); err != nil {
		return 0, err
	}
	return count, nil
}

func userExists(ctx context.Context, db *sql.DB, userID uuid.UUID) (bool, error) {
	var exists bool
	if err := db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)`, userID).Scan(&exists); err != nil {
		return false, err
	}
	return exists, nil
}

func listUserProfiles(ctx context.Context, db *sql.DB, ids []uuid.UUID, follower *uuid.UUID) ([]authorProfilePayload, error) {
	const stmt = `
SELECT u.id,
       COALESCE(NULLIF(u.display_name, ''), split_part(u.email, '@', 1)) AS display_name,
	   COALESCE(NULLIF(u.handle, ''), '@moweton') AS handle,
	   p.bio,
	   COALESCE(NULLIF(p.avatar_url, ''), NULLIF(u.avatar, '')) AS avatar,
	   (SELECT COUNT(*) FROM user_follows WHERE followee_id = u.id) AS followers,
	   (SELECT COUNT(*) FROM user_follows WHERE follower_id = u.id) AS following,
	   (SELECT COUNT(*) FROM episodes WHERE author_id = u.id AND status = 'public' AND visibility = 'public') AS posts,
	   COALESCE(p.settings, '{}'::jsonb) AS settings
FROM users u
LEFT JOIN profiles p ON p.user_id = u.id
WHERE u.id = ANY($1)
`
	rows, err := db.QueryContext(ctx, stmt, pq.Array(ids))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	type rowData struct {
		payload authorProfilePayload
		order   int
	}
	results := make(map[uuid.UUID]rowData, len(ids))
	var order int
	for rows.Next() {
		var (
			userID      uuid.UUID
			displayName string
			handle      string
			bio         sql.NullString
			avatar      sql.NullString
			followers   int
			following   int
			posts       int
			settingsRaw []byte
		)
		if err := rows.Scan(&userID, &displayName, &handle, &bio, &avatar, &followers, &following, &posts, &settingsRaw); err != nil {
			return nil, err
		}
		payload := authorProfilePayload{
			ID:          userID.String(),
			DisplayName: displayName,
			Handle:      handle,
			Followers:   followers,
			Following:   following,
			Posts:       posts,
			SocialLinks: extractSocialLinks(settingsRaw),
		}
		if bio.Valid {
			payload.Bio = &bio.String
		}
		if avatar.Valid {
			payload.Avatar = &avatar.String
		}
		results[userID] = rowData{payload: payload, order: order}
		order++
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	if follower != nil {
		followingSet, err := lookupFollowing(ctx, db, *follower, ids)
		if err != nil {
			return nil, err
		}
		for id, row := range results {
			if _, ok := followingSet[id]; ok {
				payload := row.payload
				payload.IsFollowing = true
				results[id] = rowData{payload: payload, order: row.order}
			}
		}
	}

	final := make([]authorProfilePayload, 0, len(results))
	for _, requested := range ids {
		if row, ok := results[requested]; ok {
			final = append(final, row.payload)
		}
	}
	return final, nil
}

func lookupFollowing(ctx context.Context, db *sql.DB, follower uuid.UUID, targets []uuid.UUID) (map[uuid.UUID]struct{}, error) {
	if len(targets) == 0 {
		return map[uuid.UUID]struct{}{}, nil
	}
	rows, err := db.QueryContext(ctx, `
SELECT followee_id
FROM user_follows
WHERE follower_id = $1 AND followee_id = ANY($2)
`, follower, pq.Array(targets))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	set := make(map[uuid.UUID]struct{})
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		set[id] = struct{}{}
	}
	return set, rows.Err()
}

func extractSocialLinks(raw []byte) map[string]string {
	if len(raw) == 0 {
		return nil
	}
	var settings map[string]any
	if err := json.Unmarshal(raw, &settings); err != nil {
		return nil
	}
	rawLinks, ok := settings["social_links"]
	if !ok {
		return nil
	}
	linkMap, ok := rawLinks.(map[string]any)
	if !ok {
		return nil
	}
	result := make(map[string]string)
	for key, value := range linkMap {
		strVal, ok := value.(string)
		if !ok {
			continue
		}
		trimmed := strings.TrimSpace(strVal)
		if trimmed == "" {
			continue
		}
		result[key] = trimmed
	}
	if len(result) == 0 {
		return nil
	}
	return result
}
