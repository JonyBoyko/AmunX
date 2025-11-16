package http

import (
	"net/http"
	"testing"
)

func TestCommentsListPublic(t *testing.T) {
	// Use a test episode ID (will return 404 if doesn't exist, which is fine)
	episodeID := "00000000-0000-0000-0000-000000000000"
	w, err := makeTestRequest("GET", "/v1/episodes/"+episodeID+"/comments", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	// Should return 404 (episode not found) or 200 (empty list)
	if w.Code != http.StatusOK && w.Code != http.StatusNotFound {
		t.Errorf("expected status %d or %d, got %d", http.StatusOK, http.StatusNotFound, w.Code)
	}
}

func TestCommentsCreateUnauthorized(t *testing.T) {
	episodeID := "00000000-0000-0000-0000-000000000000"
	reqBody := map[string]interface{}{
		"text": "Test comment",
	}

	w, err := makeTestRequest("POST", "/v1/episodes/"+episodeID+"/comments", reqBody, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected status %d, got %d", http.StatusUnauthorized, w.Code)
	}
}

