package http

import (
	"testing"
)

func TestMapStripeStatus(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"trialing", "trialing"},
		{"active", "active"},
		{"past_due", "past_due"},
		{"canceled", "canceled"},
		{"unknown", "expired"},
	}
	for _, tt := range tests {
		got := string(mapStripeStatus(tt.input))
		if got != tt.want {
			t.Fatalf("mapStripeStatus(%s)=%s want %s", tt.input, got, tt.want)
		}
	}
}

func TestMapRevenueCatStatus(t *testing.T) {
	tests := map[string]string{
		"INITIAL_PURCHASE": "active",
		"RENEWAL":          "active",
		"UNCANCELLATION":   "active",
		"CANCELLATION":     "canceled",
		"EXPIRATION":       "expired",
		"UNKNOWN":          "past_due",
	}
	for in, want := range tests {
		if got := string(mapRevenueCatStatus(in)); got != want {
			t.Fatalf("mapRevenueCatStatus(%s)=%s want %s", in, got, want)
		}
	}
}

func TestVerifyStripeSignature(t *testing.T) {
	body := []byte(`{"id":"evt_123"}`)
	secret := "whsec_test"
	header := "t=1700000000,v1=" + computeHexHMAC(secret, "1700000000."+string(body))
	if !verifyStripeSignature(body, header, secret) {
		t.Fatal("expected signature to match")
	}
	if verifyStripeSignature(body, header, "bad") {
		t.Fatal("expected signature mismatch for bad secret")
	}
}
