package http

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
	mw "github.com/amunx/backend/internal/http/middleware"
)

// Server bundles the HTTP server for the API.
type Server struct {
	httpServer *http.Server
	logger     zerolog.Logger
}

// NewServer constructs a configured HTTP server with middlewares and routes.
func NewServer(cfg app.Config, logger zerolog.Logger, deps *app.App) *Server {
	router := chi.NewRouter()

	router.Use(middleware.RequestID)
	router.Use(middleware.RealIP)
	router.Use(middleware.Recoverer)
	router.Use(middleware.Timeout(30 * time.Second))
	router.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{http.MethodGet, http.MethodPost, http.MethodPatch, http.MethodDelete, http.MethodOptions},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		AllowCredentials: false,
		MaxAge:           300,
	}))
	if deps.Redis != nil && cfg.RateLimitMax > 0 {
		router.Use(mw.NewRateLimiter(deps.Redis, cfg.RateLimitWindow, cfg.RateLimitMax).Handler())
	}
	router.Use(mw.Logger(logger))
	router.Use(mw.Gzip)

	router.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	router.Get("/readyz", func(w http.ResponseWriter, r *http.Request) {
		if err := deps.DB.PingContext(r.Context()); err != nil {
			http.Error(w, `{"status":"degraded"}`, http.StatusServiceUnavailable)
			return
		}
		if err := deps.Redis.Ping(r.Context()).Err(); err != nil {
			http.Error(w, `{"status":"degraded"}`, http.StatusServiceUnavailable)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	router.Route("/v1", func(r chi.Router) {
		registerAuthRoutes(r, deps, logger)
		registerPublicUserRoutes(r, deps, logger)
		registerPublicEpisodeRoutes(r, deps, logger)
		registerPublicTopicRoutes(r, deps)
		registerPublicCommentRoutes(r, deps)
		registerPublicLiveRoutes(r, deps)
		registerExploreRoutes(r, deps)
		registerSearchRoutes(r, deps)
		registerBillingWebhookRoutes(r, deps)

		r.Group(func(protected chi.Router) {
			protected.Use(mw.Auth(deps, logger))
			registerUserRoutes(protected, deps)
			registerFollowRoutes(protected, deps)
			registerEpisodeRoutes(protected, deps)
			registerTopicRoutes(protected, deps)
			registerCommentRoutes(protected, deps)
			registerReactionRoutes(protected, deps)
			registerBillingRoutes(protected, deps)
			registerPushRoutes(protected, deps)
			registerReportRoutes(protected, deps)
			registerLiveRoutes(protected, deps)
			registerModerationRoutes(protected, deps)
			if cfg.Environment == "development" {
				registerDiagnosticsRoutes(protected, deps)
			}
		})
	})

	server := &http.Server{
		Addr:         cfg.HTTPHost + ":" + itoa(cfg.HTTPPort),
		Handler:      router,
		ReadTimeout:  cfg.HTTPReadTimeout,
		WriteTimeout: cfg.HTTPWriteTimeout,
		IdleTimeout:  cfg.HTTPIdleTimeout,
	}

	return &Server{
		httpServer: server,
		logger:     logger,
	}
}

// Start begins serving HTTP requests.
func (s *Server) Start() error {
	s.logger.Info().Str("addr", s.httpServer.Addr).Msg("api server listening")
	return s.httpServer.ListenAndServe()
}

// Shutdown gracefully stops the server within the provided context deadline.
func (s *Server) Shutdown(ctx context.Context) error {
	return s.httpServer.Shutdown(ctx)
}

func itoa(v int) string {
	return fmt.Sprintf("%d", v)
}
