package http

import (
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	livekitauth "github.com/livekit/protocol/auth"

	"github.com/amunx/backend/internal/app"
)

func TestGenerateLiveTokenRoundTrip(t *testing.T) {
	cfg, err := app.LoadConfig("")
	if err != nil {
		t.Fatalf("load config: %v", err)
	}
	if cfg.LiveKitAPIKey == "" || cfg.LiveKitAPISecret == "" {
		t.Skip("LIVEKIT_API_KEY / LIVEKIT_API_SECRET not configured; skipping token verification")
	}

	token, err := generateLiveToken(cfg, "integration-room", "integration-listener", "listener", time.Now().Add(5*time.Minute))
	if err != nil {
		t.Fatalf("generateLiveToken: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}

	verifier, err := livekitauth.ParseAPIToken(token)
	if err != nil {
		t.Fatalf("ParseAPIToken: %v", err)
	}

	claims, err := verifier.Verify(cfg.LiveKitAPISecret)
	if err != nil {
		t.Fatalf("verify token: %v", err)
	}
	if claims.Video == nil || claims.Video.Room != "integration-room" {
		t.Fatalf("unexpected room claim: %+v", claims.Video)
	}
}

func TestLiveKitHealthEndpoint(t *testing.T) {
	base := os.Getenv("LIVEKIT_URL")
	if base == "" {
		t.Skip("LIVEKIT_URL not set; skipping health check")
	}
	httpURL, err := toHTTPURL(base)
	if err != nil {
		t.Fatalf("convert url: %v", err)
	}

	resp, err := http.Get(httpURL + "/healthz")
	if err != nil {
		t.Fatalf("livekit health: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 from livekit /healthz, got %d", resp.StatusCode)
	}
}

func toHTTPURL(raw string) (string, error) {
	u, err := url.Parse(raw)
	if err != nil {
		return "", err
	}
	switch strings.ToLower(u.Scheme) {
	case "wss":
		u.Scheme = "https"
	case "ws":
		u.Scheme = "http"
	case "http", "https":
	default:
		u.Scheme = "http"
	}
	u.Path = ""
	u.RawPath = ""
	u.RawQuery = ""
	u.Fragment = ""
	return strings.TrimRight(u.String(), "/"), nil
}
