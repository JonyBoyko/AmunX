package http

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	_ "github.com/lib/pq"
	"github.com/rs/zerolog"

	"github.com/amunx/backend/internal/app"
)

var (
	testApp     *app.App
	testServer  *Server
	testDB      *sql.DB
	testBaseURL string
)

func TestMain(m *testing.M) {

	// Load test config
	cfg, err := app.LoadConfig("")
	if err != nil {
		panic(fmt.Sprintf("failed to load config: %v", err))
	}

	// Override with test database if provided
	testDBURL := os.Getenv("TEST_DATABASE_URL")
	if testDBURL == "" {
		testDBURL = "postgres://test:test@localhost:5433/amunx_test?sslmode=disable"
	}
	cfg.DatabaseURL = testDBURL

	testRedisAddr := os.Getenv("TEST_REDIS_ADDRESS")
	if testRedisAddr == "" {
		testRedisAddr = "localhost:6380"
	}
	cfg.RedisAddress = testRedisAddr

	// Build test app
	ctx := context.Background()
	logger := zerolog.Nop()
	testApp, err = app.Build(ctx, cfg)
	if err != nil {
		// If database is not available, skip tests
		fmt.Printf("⚠️  Database not available, skipping integration tests: %v\n", err)
		os.Exit(0)
	}
	defer testApp.Close(ctx)

	// Create test server
	testServer = NewServer(cfg, logger, testApp)
	testBaseURL = "http://localhost:8080"

	// Run migrations (skip if fails - assume already migrated)
	_ = runMigrations(testDBURL)

	// Run tests
	code := m.Run()

	// Cleanup
	os.Exit(code)
}

func runMigrations(dbURL string) error {
	// TODO: Run migrations using migrate tool
	// For now, assume migrations are run externally
	return nil
}

func makeRequest(method, path string, body interface{}, token string) (*http.Response, error) {
	var reqBody []byte
	if body != nil {
		var err error
		reqBody, err = json.Marshal(body)
		if err != nil {
			return nil, err
		}
	}

	req, err := http.NewRequest(method, testBaseURL+path, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	return client.Do(req)
}

func makeTestRequest(method, path string, body interface{}, token string) (*httptest.ResponseRecorder, error) {
	var reqBody []byte
	if body != nil {
		var err error
		reqBody, err = json.Marshal(body)
		if err != nil {
			return nil, err
		}
	}

	req := httptest.NewRequest(method, path, bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	w := httptest.NewRecorder()
	testServer.httpServer.Handler.ServeHTTP(w, req)
	return w, nil
}

