package http

import (
	"errors"
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
			snapshot, err := store.LoadLatest(ctx, now)
			if err == nil {
				WriteJSON(w, http.StatusOK, snapshot.Response)
				return
			}
			if errors.Is(err, smartinbox.ErrNoSnapshot) {
				WriteError(
					w,
					http.StatusServiceUnavailable,
					"smart_inbox_warming_up",
					"Smart Inbox is warming up, please try again shortly.",
				)
				return
			}
			WriteError(w, http.StatusInternalServerError, "smart_inbox_failed", err.Error())
			return
		}

		rows, err := smartinbox.FetchEpisodeRows(ctx, deps.DB, limit)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "smart_inbox_failed", err.Error())
			return
		}

		resp := smartinbox.BuildResponse(rows, now)
		WriteJSON(w, http.StatusOK, resp)
	})
}
