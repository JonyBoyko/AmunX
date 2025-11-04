package http

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

type commentResponse struct {
	ID        string    `json:"id"`
	EpisodeID string    `json:"episode_id"`
	AuthorID  string    `json:"author_id"`
	Text      string    `json:"text"`
	CreatedAt time.Time `json:"created_at"`
}

func registerCommentRoutes(r chi.Router, deps *app.App) {
	r.Post("/episodes/{id}/comments", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		if currentUser.Shadowbanned {
			WriteError(w, http.StatusForbidden, "account_restricted", "commenting is disabled for this account")
			return
		}

		if allowed, retry := allowRate(req.Context(), deps.Redis, "rl:comments:user:"+currentUser.ID.String(), commentUserRateLimit, commentUserRateWindow); !allowed {
			if retry > 0 {
				w.Header().Set("Retry-After", strconv.FormatInt(int64((retry+time.Second-1)/time.Second), 10))
			}
			WriteError(w, http.StatusTooManyRequests, "rate_limited", "too many comments created recently")
			return
		}
		if ip := clientIP(req); ip != "" {
			if allowed, retry := allowRate(req.Context(), deps.Redis, "rl:comments:ip:"+ip, commentIPRateLimit, commentIPRateWindow); !allowed {
				if retry > 0 {
					w.Header().Set("Retry-After", strconv.FormatInt(int64((retry+time.Second-1)/time.Second), 10))
				}
				WriteError(w, http.StatusTooManyRequests, "rate_limited", "too many comments from this network")
				return
			}
		}

		episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}

		var payload struct {
			Text string `json:"text"`
		}
		if err := decodeJSON(req, &payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}

		if err := ensureEpisodeCommentable(req.Context(), deps.DB, episodeID, currentUser.ID); err != nil {
			switch {
			case errors.Is(err, sql.ErrNoRows):
				WriteError(w, http.StatusNotFound, "episode_not_found", "episode not found")
				return
			default:
				WriteError(w, http.StatusForbidden, "episode_not_accessible", err.Error())
				return
			}
		}

		comment, flagged, err := createComment(req.Context(), deps.DB, episodeID, currentUser.ID, payload.Text)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "comment_create_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusCreated, map[string]any{
			"comment": comment,
			"flagged": flagged,
		})
	})
}

func registerPublicCommentRoutes(r chi.Router, deps *app.App) {
	r.Get("/episodes/{id}/comments", func(w http.ResponseWriter, req *http.Request) {
		ctx := req.Context()
		episodeID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_episode_id", err.Error())
			return
		}

		var requesterID uuid.UUID
		if user, ok := httpctx.UserFromContext(ctx); ok {
			requesterID = user.ID
		}

		episode, err := getEpisodeByID(ctx, deps.DB, episodeID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "episode_not_found", "episode not found")
				return
			}
			WriteError(w, http.StatusInternalServerError, "episode_fetch_failed", err.Error())
			return
		}

		if episode.Status != "public" && episode.AuthorID != requesterID.String() {
			WriteError(w, http.StatusForbidden, "forbidden", "comments not available")
			return
		}

		limit := parseLimit(req.URL.Query().Get("limit"), 20, 100)
		var afterTime *time.Time
		if after := req.URL.Query().Get("after"); after != "" {
			ts, err := time.Parse(time.RFC3339, after)
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_after", "after must be RFC3339 timestamp")
				return
			}
			afterTime = &ts
		}

		comments, err := listEpisodeComments(ctx, deps.DB, episodeID, limit, afterTime)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "comments_list_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{"items": comments})
	})
}

func ensureEpisodeCommentable(ctx context.Context, db *sql.DB, episodeID uuid.UUID, userID uuid.UUID) error {
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

var (
	bannedWords                 = []string{"spam", "scam", "fake"}
	commentUserRateLimit  int64 = 30
	commentUserRateWindow       = time.Minute
	commentIPRateLimit    int64 = 60
	commentIPRateWindow         = 2 * time.Minute
)

func createComment(ctx context.Context, db *sql.DB, episodeID, userID uuid.UUID, text string) (commentResponse, bool, error) {
	clean := strings.TrimSpace(text)
	if clean == "" {
		return commentResponse{}, false, errors.New("text is required")
	}
	if len([]rune(clean)) > 1000 {
		return commentResponse{}, false, errors.New("text too long")
	}

	flagged := containsBannedWord(clean)

	var res commentResponse
	err := db.QueryRowContext(ctx, `
INSERT INTO comments (episode_id, author_id, text)
VALUES ($1, $2, $3)
RETURNING id, episode_id, author_id, text, created_at;
`, episodeID, userID, clean).Scan(&res.ID, &res.EpisodeID, &res.AuthorID, &res.Text, &res.CreatedAt)
	if err != nil {
		return commentResponse{}, false, err
	}

	if flagged {
		_ = flagContent(ctx, db, "comments/"+res.ID, "language", 1, "banned_word")
	}

	return res, flagged, nil
}

func listEpisodeComments(ctx context.Context, db *sql.DB, episodeID uuid.UUID, limit int, after *time.Time) ([]commentResponse, error) {
	query := `SELECT id, episode_id, author_id, text, created_at FROM comments WHERE episode_id = $1`
	args := []any{episodeID}
	if after != nil {
		query += " AND created_at < $2"
		args = append(args, *after)
	}
	placeholder := len(args) + 1
	query += " ORDER BY created_at DESC LIMIT $" + strconv.Itoa(placeholder)
	args = append(args, limit)

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []commentResponse
	for rows.Next() {
		var rec commentResponse
		if err := rows.Scan(&rec.ID, &rec.EpisodeID, &rec.AuthorID, &rec.Text, &rec.CreatedAt); err != nil {
			return nil, err
		}
		result = append(result, rec)
	}

	return result, rows.Err()
}

func containsBannedWord(text string) bool {
	lower := strings.ToLower(text)
	for _, w := range bannedWords {
		if strings.Contains(lower, w) {
			return true
		}
	}
	return false
}

func flagContent(ctx context.Context, db *sql.DB, objectRef, reason string, severity int, code string) error {
	details := reason
	if code != "" {
		details = reason + ":" + code
	}
	_, err := db.ExecContext(ctx, `
INSERT INTO moderation_flags (object_ref, severity, reason, status)
VALUES ($1, $2, $3, 'open')
ON CONFLICT DO NOTHING;
`, objectRef, severity, details)
	return err
}
