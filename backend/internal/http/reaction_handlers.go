package http

import (
	"context"
	"database/sql"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

// registerReactionRoutes wires reaction endpoints under protected routes.
func registerReactionRoutes(r chi.Router, deps *app.App) {
	// Toggle/add/remove a reaction for current user
	r.Post("/episodes/{id}/react", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}

		var payload struct {
			Type   string `json:"type"`
			Remove bool   `json:"remove"`
		}
		if err := decodeJSON(req, &payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}
		reactType := sanitizeReactionType(payload.Type)
		if reactType == "" {
			reactType = "like"
		}

		// Only allow reactions if episode is public or owned by the user
		if err := ensureEpisodeReactable(req.Context(), deps.DB, episodeID, currentUser.ID); err != nil {
			switch {
			case errors.Is(err, sql.ErrNoRows):
				WriteError(w, http.StatusNotFound, "episode_not_found", "episode not found")
				return
			default:
				WriteError(w, http.StatusForbidden, "episode_not_accessible", err.Error())
				return
			}
		}

		if payload.Remove {
			if err := removeReaction(req.Context(), deps.DB, episodeID, currentUser.ID, reactType); err != nil {
				WriteError(w, http.StatusInternalServerError, "reaction_update_failed", err.Error())
				return
			}
		} else {
			if err := addReaction(req.Context(), deps.DB, episodeID, currentUser.ID, reactType); err != nil {
				WriteError(w, http.StatusInternalServerError, "reaction_update_failed", err.Error())
				return
			}
		}

		self, err := listSelfReactions(req.Context(), deps.DB, episodeID, currentUser.ID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "reactions_fetch_failed", err.Error())
			return
		}
		totals, badge, err := loadReactionSnapshot(req.Context(), deps.DB, episodeID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "reactions_fetch_failed", err.Error())
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{
			"ok":     true,
			"self":   self,
			"totals": totals,
			"badge":  badge,
		})
	})

	// Return current user's reactions for the episode
	r.Get("/episodes/{id}/reactions/self", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}
		// episode existence not strictly required to read self reactions, but check to align with comments
		if _, err := getEpisodeByID(req.Context(), deps.DB, episodeID); err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "episode_not_found", "episode not found")
				return
			}
		}
		self, err := listSelfReactions(req.Context(), deps.DB, episodeID, currentUser.ID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "reactions_fetch_failed", err.Error())
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{"self": self})
	})
}

func ensureEpisodeReactable(ctx context.Context, db *sql.DB, episodeID uuid.UUID, userID uuid.UUID) error {
	const query = `SELECT author_id, status FROM episodes WHERE id = $1`
	var (
		author uuid.UUID
		status string
	)
	if err := db.QueryRowContext(ctx, query, episodeID).Scan(&author, &status); err != nil {
		return err
	}
	if status != "public" && author != userID {
		return errors.New("episode not public")
	}
	return nil
}

func addReaction(ctx context.Context, db *sql.DB, episodeID, userID uuid.UUID, reactType string) error {
	_, err := db.ExecContext(ctx, `
INSERT INTO reactions (episode_id, user_id, type)
VALUES ($1, $2, $3)
ON CONFLICT (episode_id, user_id, type) DO NOTHING;
`, episodeID, userID, reactType)
	return err
}

func removeReaction(ctx context.Context, db *sql.DB, episodeID, userID uuid.UUID, reactType string) error {
	_, err := db.ExecContext(ctx, `DELETE FROM reactions WHERE episode_id = $1 AND user_id = $2 AND type = $3`, episodeID, userID, reactType)
	return err
}

func listSelfReactions(ctx context.Context, db *sql.DB, episodeID, userID uuid.UUID) ([]string, error) {
	rows, err := db.QueryContext(ctx, `SELECT type FROM reactions WHERE episode_id = $1 AND user_id = $2`, episodeID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var result []string
	for rows.Next() {
		var t string
		if err := rows.Scan(&t); err != nil {
			return nil, err
		}
		if canonical := canonicalReactionType(t); canonical != "" {
			result = append(result, canonical)
		}
	}
	return result, rows.Err()
}

func sanitizeReactionType(t string) string {
	return canonicalReactionType(t)
}
