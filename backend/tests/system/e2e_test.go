package system

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"
)

var (
	baseURL = "http://localhost:8080"
	token   string
)

func TestMain(m *testing.M) {
	// Check if API is running
	if url := os.Getenv("API_BASE_URL"); url != "" {
		baseURL = url
	}

	// Wait for API to be ready
	if err := waitForAPI(baseURL, 30*time.Second); err != nil {
		fmt.Printf("API not ready: %v\n", err)
		os.Exit(1)
	}

	// Run tests
	code := m.Run()
	os.Exit(code)
}

func waitForAPI(url string, timeout time.Duration) error {
	client := &http.Client{Timeout: 5 * time.Second}
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		resp, err := client.Get(url + "/healthz")
		if err == nil && resp.StatusCode == http.StatusOK {
			return nil
		}
		time.Sleep(1 * time.Second)
	}

	return fmt.Errorf("timeout waiting for API")
}

func TestHealthCheck(t *testing.T) {
	resp, err := http.Get(baseURL + "/healthz")
	if err != nil {
		t.Fatalf("failed to check health: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, resp.StatusCode)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if status, ok := result["status"].(string); !ok || status != "ok" {
		t.Errorf("expected status 'ok', got %v", result["status"])
	}
}

func TestReadinessCheck(t *testing.T) {
	resp, err := http.Get(baseURL + "/readyz")
	if err != nil {
		t.Fatalf("failed to check readiness: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("unexpected status: %d", resp.StatusCode)
	}
}

func TestMagicLinkFlow(t *testing.T) {
	// Request magic link
	reqBody := map[string]string{
		"email": "e2e-test@example.com",
	}

	body, _ := json.Marshal(reqBody)
	resp, err := http.Post(baseURL+"/v1/auth/magiclink", "application/json", bytes.NewBuffer(body))
	if err != nil {
		t.Fatalf("failed to request magic link: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted {
		t.Errorf("expected status %d, got %d", http.StatusAccepted, resp.StatusCode)
	}

	// Note: In real E2E test, we would extract token from email
	// For now, we just verify the endpoint works
}

func TestEpisodesList(t *testing.T) {
	resp, err := http.Get(baseURL + "/v1/episodes")
	if err != nil {
		t.Fatalf("failed to list episodes: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, resp.StatusCode)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if items, ok := result["items"].([]interface{}); ok {
		t.Logf("found %d episodes", len(items))
	}
}


