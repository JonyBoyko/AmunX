package smartinbox

import (
	"database/sql"
	"testing"
	"time"

	"github.com/lib/pq"
)

func TestBuildResponse(t *testing.T) {
	now := time.Date(2024, 1, 10, 12, 0, 0, 0, time.UTC)
	rows := []EpisodeRow{
		{
			ID:        "today-1",
			Title:     "Morning update",
			AuthorID:  "author-1",
			Summary:   sqlString("Fresh AI tricks"),
			Keywords:  pqStringArray("ai", "growth"),
			CreatedAt: now,
		},
		{
			ID:        "yesterday-1",
			Title:     "No summary",
			AuthorID:  "author-2",
			Keywords:  pqStringArray("founders"),
			CreatedAt: now.Add(-26 * time.Hour),
		},
		{
			ID:        "yesterday-2",
			Title:     "Another",
			AuthorID:  "author-3",
			Summary:   sqlString("Quick check-in"),
			Keywords:  pqStringArray("growth"),
			CreatedAt: now.Add(-25 * time.Hour),
		},
	}

	resp := BuildResponse(rows, now)
	if len(resp.Digests) != 2 {
		t.Fatalf("expected 2 digests, got %d", len(resp.Digests))
	}
	if resp.Digests[0].Entries[0].EpisodeID != "today-1" {
		t.Fatalf("expected newest entry first, got %+v", resp.Digests[0].Entries[0])
	}
	if len(resp.Highlights) == 0 || resp.Highlights[0] != "growth" {
		t.Fatalf("expected growth highlight, got %+v", resp.Highlights)
	}
	if len(resp.Highlights) > 1 && resp.Highlights[0] == resp.Highlights[len(resp.Highlights)-1] {
		t.Fatalf("expected sorted highlights %+v", resp.Highlights)
	}
	if resp.GeneratedAt != now.Format(time.RFC3339) {
		t.Fatalf("expected generated_at %s, got %s", now.Format(time.RFC3339), resp.GeneratedAt)
	}
	if resp.Digests[0].Summary == "" {
		t.Fatalf("expected summary to be populated")
	}
}

func sqlString(value string) sql.NullString {
	return sql.NullString{String: value, Valid: true}
}

func pqStringArray(values ...string) pq.StringArray {
	return pq.StringArray(values)
}
