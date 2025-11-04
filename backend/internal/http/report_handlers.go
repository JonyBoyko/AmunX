package http

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/httpctx"
)

var reportObjectPattern = regexp.MustCompile(`^(episodes|comments)/[0-9a-fA-F-]{36}$`)

func registerReportRoutes(r chi.Router, deps *app.App) {
	r.Route("/reports", func(rr chi.Router) {
		rr.Post("/", func(w http.ResponseWriter, req *http.Request) {
			user, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}
			if deps.Redis != nil {
				if allowed, retryAfter := allowReport(req.Context(), deps, user.ID); !allowed {
					w.Header().Set("Retry-After", retryAfter.String())
					WriteError(w, http.StatusTooManyRequests, "rate_limited", "too many reports submitted")
					return
				}
			}

			var payload struct {
				ObjectRef string `json:"object_ref"`
				Reason    string `json:"reason"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}

			objectRef := strings.TrimSpace(payload.ObjectRef)
			if !reportObjectPattern.MatchString(objectRef) {
				WriteError(w, http.StatusBadRequest, "invalid_object_ref", "object_ref must be episodes/{uuid} or comments/{uuid}")
				return
			}
			if err := ensureReportableObject(req.Context(), deps.DB, objectRef); err != nil {
				switch {
				case errors.Is(err, sql.ErrNoRows):
					WriteError(w, http.StatusNotFound, "object_not_found", "reported object not found")
					return
				default:
					WriteError(w, http.StatusInternalServerError, "object_lookup_failed", err.Error())
					return
				}
			}

			reason := strings.TrimSpace(payload.Reason)
			if len(reason) > 512 {
				reason = reason[:512]
			}

			report, err := createReport(req.Context(), deps.DB, objectRef, reason, user.ID)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "report_create_failed", err.Error())
				return
			}

			WriteJSON(w, http.StatusCreated, map[string]any{"report": report})
		})

		rr.Get("/", func(w http.ResponseWriter, req *http.Request) {
			user, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}
			reports, err := listReportsByReporter(req.Context(), deps.DB, user.ID, 50)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "reports_fetch_failed", err.Error())
				return
			}
			WriteJSON(w, http.StatusOK, map[string]any{"items": reports})
		})

		rr.Get("/open", func(w http.ResponseWriter, req *http.Request) {
			user, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}
			if !isModerator(user) {
				WriteError(w, http.StatusForbidden, "forbidden", "moderator access required")
				return
			}
			reports, err := listOpenReports(req.Context(), deps.DB, 100)
			if err != nil {
				WriteError(w, http.StatusInternalServerError, "reports_fetch_failed", err.Error())
				return
			}
			WriteJSON(w, http.StatusOK, map[string]any{"items": reports})
		})

		rr.Patch("/{id}", func(w http.ResponseWriter, req *http.Request) {
			user, ok := httpctx.UserFromContext(req.Context())
			if !ok {
				WriteError(w, http.StatusInternalServerError, "user_context_missing", "failed to resolve user")
				return
			}
			if !isModerator(user) {
				WriteError(w, http.StatusForbidden, "forbidden", "moderator access required")
				return
			}
			reportID, err := uuidFromParam(chi.URLParam(req, "id"))
			if err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_report_id", err.Error())
				return
			}
			var payload struct {
				Status string `json:"status"`
			}
			if err := decodeJSON(req, &payload); err != nil {
				WriteError(w, http.StatusBadRequest, "invalid_request", err.Error())
				return
			}
			status := strings.ToLower(strings.TrimSpace(payload.Status))
			if !isValidReportStatus(status) {
				WriteError(w, http.StatusBadRequest, "invalid_status", "status must be open, review, or actioned")
				return
			}
			report, err := updateReportStatus(req.Context(), deps.DB, reportID, status)
			if err != nil {
				if errors.Is(err, sql.ErrNoRows) {
					WriteError(w, http.StatusNotFound, "report_not_found", "report not found")
					return
				}
				WriteError(w, http.StatusInternalServerError, "report_update_failed", err.Error())
				return
			}
			WriteJSON(w, http.StatusOK, map[string]any{"report": report})
		})
	})
}

type reportRecord struct {
	ID        string    `json:"id"`
	ObjectRef string    `json:"object_ref"`
	Reason    string    `json:"reason"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

func isModerator(user httpctx.User) bool {
	return strings.EqualFold(user.Plan, "staff")
}

func isValidReportStatus(status string) bool {
	switch status {
	case "open", "review", "actioned":
		return true
	default:
		return false
	}
}

func allowReport(ctx context.Context, deps *app.App, userID uuid.UUID) (bool, time.Duration) {
	const (
		limit     = 5
		window    = time.Minute * 10
		redisRate = "rl:reports:"
	)
	if deps.Redis == nil {
		return true, 0
	}
	key := redisRate + userID.String()
	count, err := deps.Redis.Incr(ctx, key).Result()
	if err != nil {
		return true, 0
	}
	if count == 1 {
		_ = deps.Redis.Expire(ctx, key, window).Err()
	} else if count > limit {
		ttl, err := deps.Redis.TTL(ctx, key).Result()
		if err != nil || ttl < 0 {
			ttl = window
		}
		return false, ttl
	}
	return true, 0
}

func ensureReportableObject(ctx context.Context, db *sql.DB, objectRef string) error {
	parts := strings.Split(objectRef, "/")
	if len(parts) != 2 {
		return errors.New("invalid object_ref")
	}
	id, err := uuid.Parse(parts[1])
	if err != nil {
		return err
	}
	switch parts[0] {
	case "episodes":
		const query = `SELECT 1 FROM episodes WHERE id = $1`
		return db.QueryRowContext(ctx, query, id).Scan(new(int))
	case "comments":
		const query = `SELECT 1 FROM comments WHERE id = $1`
		return db.QueryRowContext(ctx, query, id).Scan(new(int))
	default:
		return errors.New("object type not supported")
	}
}

func createReport(ctx context.Context, db *sql.DB, objectRef, reason string, reporterID uuid.UUID) (reportRecord, error) {
	const query = `
INSERT INTO reports (object_ref, reporter_id, reason, status)
VALUES ($1, $2, $3, 'open')
RETURNING id, object_ref, reason, status, created_at;
`
	var rec reportRecord
	err := db.QueryRowContext(ctx, query, objectRef, reporterID, reason).Scan(
		&rec.ID,
		&rec.ObjectRef,
		&rec.Reason,
		&rec.Status,
		&rec.CreatedAt,
	)
	return rec, err
}

func listReportsByReporter(ctx context.Context, db *sql.DB, reporterID uuid.UUID, limit int) ([]reportRecord, error) {
	const query = `
SELECT id, object_ref, reason, status, created_at
FROM reports
WHERE reporter_id = $1
ORDER BY created_at DESC
LIMIT $2;
`
	rows, err := db.QueryContext(ctx, query, reporterID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []reportRecord
	for rows.Next() {
		var rec reportRecord
		if err := rows.Scan(&rec.ID, &rec.ObjectRef, &rec.Reason, &rec.Status, &rec.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, rec)
	}
	return items, rows.Err()
}

func listOpenReports(ctx context.Context, db *sql.DB, limit int) ([]reportRecord, error) {
	const query = `
SELECT id, object_ref, reason, status, created_at
FROM reports
WHERE status = 'open'
ORDER BY created_at DESC
LIMIT $1;
`
	rows, err := db.QueryContext(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []reportRecord
	for rows.Next() {
		var rec reportRecord
		if err := rows.Scan(&rec.ID, &rec.ObjectRef, &rec.Reason, &rec.Status, &rec.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, rec)
	}
	return items, rows.Err()
}

func updateReportStatus(ctx context.Context, db *sql.DB, id uuid.UUID, status string) (reportRecord, error) {
	const query = `
UPDATE reports
SET status = $2
WHERE id = $1
RETURNING id, object_ref, reason, status, created_at;
`
	var rec reportRecord
	err := db.QueryRowContext(ctx, query, id, status).Scan(
		&rec.ID,
		&rec.ObjectRef,
		&rec.Reason,
		&rec.Status,
		&rec.CreatedAt,
	)
	return rec, err
}
