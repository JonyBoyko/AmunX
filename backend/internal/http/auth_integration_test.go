package http

import (
	"encoding/json"
	"net/http"
	"testing"
)

func TestAuthMagicLinkFlow(t *testing.T) {
	// Request magic link
	reqBody := map[string]string{
		"email": "test@example.com",
	}

	w, err := makeTestRequest("POST", "/v1/auth/magiclink", reqBody, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusAccepted {
		t.Errorf("expected status %d, got %d", http.StatusAccepted, w.Code)
		t.Logf("response body: %s", w.Body.String())
	}

	var response map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}

	if status, ok := response["status"].(string); !ok || status != "sent" {
		t.Errorf("expected status 'sent', got %v", response["status"])
	}
}

func TestAuthMagicLinkInvalidEmail(t *testing.T) {
	testCases := []struct {
		name  string
		email string
	}{
		{"empty email", ""},
		{"invalid format", "not-an-email"},
		{"missing @", "testexample.com"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			reqBody := map[string]string{
				"email": tc.email,
			}

			w, err := makeTestRequest("POST", "/v1/auth/magiclink", reqBody, "")
			if err != nil {
				t.Fatalf("failed to make request: %v", err)
			}

			if w.Code != http.StatusBadRequest {
				t.Errorf("expected status %d, got %d", http.StatusBadRequest, w.Code)
			}
		})
	}
}

func TestAuthMagicLinkVerifyInvalidToken(t *testing.T) {
	reqBody := map[string]string{
		"token": "invalid-token",
	}

	w, err := makeTestRequest("POST", "/v1/auth/magiclink/verify", reqBody, "")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected status %d, got %d", http.StatusUnauthorized, w.Code)
	}
}

func TestHealthEndpoints(t *testing.T) {
	testCases := []struct {
		name string
		path string
	}{
		{"healthz", "/healthz"},
		{"readyz", "/readyz"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			w, err := makeTestRequest("GET", tc.path, nil, "")
			if err != nil {
				t.Fatalf("failed to make request: %v", err)
			}

			if w.Code != http.StatusOK {
				t.Errorf("expected status %d, got %d", http.StatusOK, w.Code)
			}

			var response map[string]interface{}
			if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
				t.Fatalf("failed to parse response: %v", err)
			}

			if status, ok := response["status"].(string); !ok || status != "ok" {
				t.Errorf("expected status 'ok', got %v", response["status"])
			}
		})
	}
}


