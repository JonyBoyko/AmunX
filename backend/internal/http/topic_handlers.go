package http

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

var errTopicNotAccessible = errors.New("cannot follow private topic")

type topicSummary struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Slug        string    `json:"slug"`
	Description *string   `json:"description,omitempty"`
	IsPublic    bool      `json:"is_public"`
	CreatedAt   time.Time `json:"created_at"`
	IsOwner     bool      `json:"is_owner"`
	IsFollowing bool      `json:"is_following"`
}

type topicDetail struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Slug        string    `json:"slug"`
	Description *string   `json:"description,omitempty"`
	IsPublic    bool      `json:"is_public"`
	CreatedAt   time.Time `json:"created_at"`
	OwnerID     *string   `json:"owner_id,omitempty"`
	IsOwner     bool      `json:"is_owner"`
	IsFollowing bool      `json:"is_following"`
}

func registerTopicRoutes(r chi.Router, deps *app.App) {
	r.Post("/topics", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		var payload struct {
			Title       string `json:"title"`
			Description string `json:"description"`
			IsPublic    *bool  `json:"is_public"`
		}
		if err := decodeJSON(req, &payload); err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
			return
		}

		if strings.TrimSpace(payload.Title) == "" {
			WriteError(w, http.StatusBadRequest, "invalid_title", "title is required")
			return
		}

		isPublic := true
		if payload.IsPublic != nil {
			isPublic = *payload.IsPublic
		}

		topic, err := createTopic(req.Context(), deps.DB, currentUser.ID, payload.Title, payload.Description, isPublic)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "topic_create_failed", err.Error())
			return
		}

		topic.IsOwner = true
		WriteJSON(w, http.StatusCreated, topic)
	})

	r.Post("/topics/{id}/follow", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		topicID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_topic_id", err.Error())
			return
		}

		if err := followTopic(req.Context(), deps.DB, topicID, currentUser.ID); err != nil {
			switch {
			case errors.Is(err, sql.ErrNoRows):
				WriteError(w, http.StatusNotFound, "not_found", "topic not found")
				return
			case errors.Is(err, errTopicNotAccessible):
				WriteError(w, http.StatusForbidden, "forbidden", err.Error())
				return
			default:
				WriteError(w, http.StatusInternalServerError, "topic_follow_failed", err.Error())
				return
			}
		}

		WriteJSON(w, http.StatusOK, map[string]any{"status": "followed"})
	})

	r.Delete("/topics/{id}/follow", func(w http.ResponseWriter, req *http.Request) {
		currentUser, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}

		topicID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_topic_id", err.Error())
			return
		}

		if err := unfollowTopic(req.Context(), deps.DB, topicID, currentUser.ID); err != nil {
			WriteError(w, http.StatusInternalServerError, "topic_unfollow_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{"status": "unfollowed"})
	})
}

func registerPublicTopicRoutes(r chi.Router, deps *app.App) {
	r.Get("/topics", func(w http.ResponseWriter, req *http.Request) {
		ctx := req.Context()
		query := strings.TrimSpace(req.URL.Query().Get("query"))
		page := parseLimit(req.URL.Query().Get("page"), 1, 1000)
		if page < 1 {
			page = 1
		}
		limit := 20
		offset := (page - 1) * limit

		var currentID uuid.UUID
		if user, ok := httpctx.UserFromContext(ctx); ok {
			currentID = user.ID
		}

		items, err := listTopics(ctx, deps.DB, query, limit, offset, currentID)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "topics_list_failed", err.Error())
			return
		}

		WriteJSON(w, http.StatusOK, map[string]any{
			"items": items,
			"page":  page,
		})
	})

	r.Get("/topics/{id}", func(w http.ResponseWriter, req *http.Request) {
		ctx := req.Context()
		topicID, err := uuidFromParam(chi.URLParam(req, "id"))
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_topic_id", err.Error())
			return
		}

		var currentID uuid.UUID
		user, ok := httpctx.UserFromContext(ctx)
		if ok {
			currentID = user.ID
		}

		topic, err := getTopicByID(ctx, deps.DB, topicID, currentID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				WriteError(w, http.StatusNotFound, "not_found", "topic not found")
				return
			}
			WriteError(w, http.StatusInternalServerError, "topic_fetch_failed", err.Error())
			return
		}

		if !topic.IsPublic && (!ok || topic.OwnerID == nil || *topic.OwnerID != currentID.String()) {
			WriteError(w, http.StatusForbidden, "forbidden", "topic not available")
			return
		}

		WriteJSON(w, http.StatusOK, topic)
	})
}

func createTopic(ctx context.Context, db *sql.DB, owner uuid.UUID, title, description string, isPublic bool) (topicSummary, error) {
	baseSlug := slugify(title)
	if baseSlug == "" {
		baseSlug = "topic"
	}

	for i := 0; i < 6; i++ {
		slug := baseSlug
		if i > 0 {
			slug = fmt.Sprintf("%s-%s", baseSlug, uuid.NewString()[:4])
		}

		var res topicSummary
		err := db.QueryRowContext(ctx, `
INSERT INTO topics (title, slug, owner_id, is_public, description)
VALUES ($1, $2, $3, $4, NULLIF($5, ''))
RETURNING id, title, slug, description, is_public, created_at;
`, title, slug, owner, isPublic, description).Scan(
			&res.ID,
			&res.Title,
			&res.Slug,
			&res.Description,
			&res.IsPublic,
			&res.CreatedAt,
		)
		if err == nil {
			return res, nil
		}
		if !isUniqueViolation(err) {
			return topicSummary{}, err
		}
	}

	return topicSummary{}, errors.New("could not generate unique slug")
}

func listTopics(ctx context.Context, db *sql.DB, search string, limit, offset int, currentUser uuid.UUID) ([]topicSummary, error) {
	query := `
SELECT t.id, t.title, t.slug, t.description, t.is_public, t.created_at,
       CASE WHEN t.owner_id = $1 THEN true ELSE false END AS is_owner,
       CASE WHEN f.user_id IS NOT NULL THEN true ELSE false END AS is_following
FROM topics t
LEFT JOIN follows f ON f.topic_id = t.id AND f.user_id = $1
WHERE t.is_public = true`
	args := []any{currentUser}
	placeholder := 2

	if search != "" {
		query += fmt.Sprintf(" AND t.title ILIKE $%d", placeholder)
		args = append(args, "%"+search+"%")
		placeholder++
	}

	query += fmt.Sprintf(" ORDER BY t.created_at DESC LIMIT $%d OFFSET $%d", placeholder, placeholder+1)
	args = append(args, limit, offset)

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []topicSummary
	for rows.Next() {
		var (
			rec  topicSummary
			desc sql.NullString
		)
		if err := rows.Scan(&rec.ID, &rec.Title, &rec.Slug, &desc, &rec.IsPublic, &rec.CreatedAt, &rec.IsOwner, &rec.IsFollowing); err != nil {
			return nil, err
		}
		if desc.Valid {
			rec.Description = &desc.String
		}
		items = append(items, rec)
	}

	return items, rows.Err()
}

func getTopicByID(ctx context.Context, db *sql.DB, id uuid.UUID, currentUser uuid.UUID) (topicDetail, error) {
	const query = `
SELECT t.id, t.title, t.slug, t.description, t.is_public, t.created_at, t.owner_id,
       CASE WHEN t.owner_id = $2 THEN true ELSE false END AS is_owner,
       CASE WHEN f.user_id IS NOT NULL THEN true ELSE false END AS is_following
FROM topics t
LEFT JOIN follows f ON f.topic_id = t.id AND f.user_id = $2
WHERE t.id = $1;
`
	var (
		rec     topicDetail
		desc    sql.NullString
		ownerID sql.NullString
	)
	err := db.QueryRowContext(ctx, query, id, currentUser).Scan(
		&rec.ID,
		&rec.Title,
		&rec.Slug,
		&desc,
		&rec.IsPublic,
		&rec.CreatedAt,
		&ownerID,
		&rec.IsOwner,
		&rec.IsFollowing,
	)
	if err != nil {
		return topicDetail{}, err
	}
	if desc.Valid {
		rec.Description = &desc.String
	}
	if ownerID.Valid {
		value := ownerID.String
		rec.OwnerID = &value
	}
	return rec, nil
}

func followTopic(ctx context.Context, db *sql.DB, topicID, userID uuid.UUID) error {
	const check = `SELECT owner_id, is_public FROM topics WHERE id = $1`
	var (
		owner    uuid.UUID
		isPublic bool
	)
	if err := db.QueryRowContext(ctx, check, topicID).Scan(&owner, &isPublic); err != nil {
		return err
	}
	if !isPublic && owner != userID {
		return errTopicNotAccessible
	}

	_, err := db.ExecContext(ctx, `
INSERT INTO follows (user_id, topic_id)
VALUES ($1, $2)
ON CONFLICT (user_id, topic_id) DO NOTHING;
`, userID, topicID)
	return err
}

func unfollowTopic(ctx context.Context, db *sql.DB, topicID, userID uuid.UUID) error {
	_, err := db.ExecContext(ctx, `DELETE FROM follows WHERE user_id = $1 AND topic_id = $2`, userID, topicID)
	return err
}

func slugify(input string) string {
	s := strings.ToLower(strings.TrimSpace(input))
	s = strings.ReplaceAll(s, "'", "")
	s = strings.ReplaceAll(s, "\"", "")
	s = strings.ReplaceAll(s, "&", "and")

	var b strings.Builder
	prevDash := false
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			prevDash = false
			b.WriteRune(r)
		case r == ' ' || r == '-' || r == '_':
			if prevDash {
				continue
			}
			prevDash = true
			b.WriteRune('-')
		default:
			prevDash = false
		}
	}

	return strings.Trim(b.String(), "-")
}

func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "duplicate key")
}

