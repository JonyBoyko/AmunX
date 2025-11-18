package http

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/amunx/backend/internal/app"
	"github.com/amunx/backend/internal/smartinbox"
)

const (
	smartInboxDefaultLimit = 60
	smartInboxMaxLimit     = 200
)

func registerSmartInboxRoutes(r chi.Router, deps *app.App) {
	store := smartinbox.NewStore(deps.DB)

	r.Get("/smart-inbox", func(w http.ResponseWriter, req *http.Request) {
		limit := getIntQueryParam(req, "limit", smartInboxDefaultLimit)
		if limit <= 0 {
			limit = smartInboxDefaultLimit
		}
		if limit > smartInboxMaxLimit {
			limit = smartInboxMaxLimit
		}

		ctx := req.Context()
		now := time.Now().UTC()

		if limit == smartInboxDefaultLimit {
			if snapshot, err := store.LoadLatest(ctx, now); err == nil {
				WriteJSON(w, http.StatusOK, snapshot.Response)
				return
			}
		}

		rows, err := smartinbox.FetchEpisodeRows(ctx, deps.DB, limit)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "smart_inbox_failed", err.Error())
			return
		}

		resp := smartinbox.BuildResponse(rows, now)
		if err := store.Save(ctx, resp, now, smartinbox.DefaultSnapshotTTL, len(rows)); err == nil {
			_ = store.Prune(ctx, now.Add(-24*time.Hour))
		}

		WriteJSON(w, http.StatusOK, resp)
	})
}
