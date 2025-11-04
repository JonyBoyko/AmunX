package http

import (
	"context"
	"database/sql"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

type moderationFlagRecord struct {
	ID        string `json:"id"`
	ObjectRef string `json:"object_ref"`
	Severity  int    `json:"severity"`
	Reason    string `json:"reason"`
	Status    string `json:"status"`
	CreatedAt string `json:"created_at"`
}

func registerModerationRoutes(r chi.Router, deps *app.App) {
	r.Get("/mod/flags", func(w http.ResponseWriter, req *http.Request) {
		user, ok := httpctx.UserFromContext(req.Context())
		if !ok {
			WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
			return
		}
		if !isModerator(user) {
			WriteError(w, http.StatusForbidden, "forbidden", "moderator access required")
			return
		}

		status := strings.TrimSpace(req.URL.Query().Get("status"))
		if status == "" {
			status = "open"
		}
		status = strings.ToLower(status)
		switch status {
		case "open", "review", "actioned":
		default:
			WriteError(w, http.StatusBadRequest, "invalid_status", "status must be open, review, or actioned")
			return
		}

		flags, err := listModerationFlags(req.Context(), deps.DB, status, 100)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "flags_fetch_failed", err.Error())
			return
		}
		WriteJSON(w, http.StatusOK, map[string]any{"items": flags})
	})
}

func listModerationFlags(ctx context.Context, db *sql.DB, status string, limit int) ([]moderationFlagRecord, error) {
	const query = `
SELECT id, object_ref, severity, reason, status, created_at
FROM moderation_flags
WHERE status = $1
ORDER BY created_at DESC
LIMIT $2;
`
	rows, err := db.QueryContext(ctx, query, status, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []moderationFlagRecord
	for rows.Next() {
		var rec moderationFlagRecord
		if err := rows.Scan(&rec.ID, &rec.ObjectRef, &rec.Severity, &rec.Reason, &rec.Status, &rec.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, rec)
	}
	return items, rows.Err()
}
