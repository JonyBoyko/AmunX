package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"

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
		})
	})
}
