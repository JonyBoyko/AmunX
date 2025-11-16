package http

import (
	"encoding/json"
	"net/http"
	"testing"
)

func TestEpisodesListPublic(t *testing.T) {
	w, err := makeTestRequest("GET", "/v1/episodes", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, w.Code)
		t.Logf("response body: %s", w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	// Response might be empty array or object with items
	if items, ok := response["items"].([]interface{}); ok {
		t.Logf("found %d episodes", len(items))
	} else if response["items"] == nil {
		// Empty response is also valid
		t.Logf("empty episodes list")
	} else {
		t.Errorf("expected 'items' array, got %T", response["items"])
	}
}

func TestEpisodesCreateUnauthorized(t *testing.T) {
	reqBody := map[string]interface{}{
		"visibility":  "public",
		"mask":        "none",
		"quality":     "clean",
		"duration_sec": 60,
	}

	w, err := makeTestRequest("POST", "/v1/episodes", reqBody, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected status %d, got %d", http.StatusUnauthorized, w.Code)
	}
}

func TestEpisodesGetNotFound(t *testing.T) {
	w, err := makeTestRequest("GET", "/v1/episodes/00000000-0000-0000-0000-000000000000", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusNotFound {
		t.Errorf("expected status %d, got %d", http.StatusNotFound, w.Code)
	}
}

