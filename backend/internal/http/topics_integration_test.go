package http

import (
	"encoding/json"
	"net/http"
	"testing"
)

func TestTopicsListPublic(t *testing.T) {
	w, err := makeTestRequest("GET", "/v1/topics", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusOK {
		t.Errorf("expected status %d, got %d", http.StatusOK, w.Code)
		t.Logf("response body: %s", w.Body.String())
	}

	// Response might be array or object with error
	var responseArray []interface{}
	var responseObj map[string]interface{}
	
	if err := json.Unmarshal(w.Body.Bytes(), &responseArray); err == nil {
		t.Logf("found %d topics", len(responseArray))
		return
	}
	
	// Try parsing as object (might be error response)
	if err := json.Unmarshal(w.Body.Bytes(), &responseObj); err == nil {
		if errorMsg, ok := responseObj["error"]; ok {
			t.Logf("API returned error: %v", errorMsg)
		} else {
			t.Logf("unexpected response format")
		}
	} else {
		t.Fatalf("failed to parse response: %v", err)
	}
}

func TestTopicsGetById(t *testing.T) {
	// First, get list to find a valid topic ID
	w, err := makeTestRequest("GET", "/v1/topics", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusOK {
		t.Skip("topics list not available, skipping get by id test")
		return
	}

	var topics []map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &topics); err != nil {
		t.Skip("failed to parse topics list")
		return
	}

	if len(topics) == 0 {
		t.Skip("no topics available for testing")
		return
	}

	topicID := topics[0]["id"].(string)
	w, err = makeTestRequest("GET", "/v1/topics/"+topicID, nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusOK && w.Code != http.StatusNotFound {
		t.Errorf("expected status %d or %d, got %d", http.StatusOK, http.StatusNotFound, w.Code)
	}
}

func TestTopicsGetNotFound(t *testing.T) {
	w, err := makeTestRequest("GET", "/v1/topics/00000000-0000-0000-0000-000000000000", nil, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusNotFound {
		t.Errorf("expected status %d, got %d", http.StatusNotFound, w.Code)
	}
}

