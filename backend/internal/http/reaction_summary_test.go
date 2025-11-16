package http

import "testing"

func TestCanonicalReactionType(t *testing.T) {
	cases := map[string]string{
		"FIRE":        "fire",
		" thumbs_up ": "like",
		"idea":        "idea",
		"LIGHTBULB":   "idea",
		"heart":       "heart",
		"":            "",
		"unknown":     "",
	}

	for input, expected := range cases {
		if got := canonicalReactionType(input); got != expected {
			t.Fatalf("canonicalReactionType(%q)=%q, want %q", input, got, expected)
		}
	}
}

func TestDeriveReactionBadge(t *testing.T) {
	counts := []reactionCount{
		{Type: "fire", Count: 32},
		{Type: "like", Count: 11},
	}
	badge := deriveReactionBadge(counts)
	if badge == nil {
		t.Fatalf("expected badge for counts %+v", counts)
	}
	if badge.Type != "fire" || badge.Level != 2 {
		t.Fatalf("unexpected badge %+v", badge)
	}

	lowCounts := []reactionCount{
		{Type: "fire", Count: 5},
	}
	if deriveReactionBadge(lowCounts) != nil {
		t.Fatalf("expected nil badge for low counts")
	}
}
