package smartinbox

import (
	"sort"
	"strings"
	"time"
	"unicode/utf8"
)

const digestSummaryLimit = 220

// BuildResponse groups raw episode rows into a Smart Inbox response.
func BuildResponse(rows []EpisodeRow, now time.Time) Response {
	groups := make(map[string][]Entry)
	var order []string
	highlightCounts := make(map[string]int)

	for _, row := range rows {
		dateKey := row.CreatedAt.Format("2006-01-02")
		entry := Entry{
			EpisodeID: row.ID,
			Title:     strings.TrimSpace(row.Title),
			AuthorID:  row.AuthorID,
			Snippet:   buildSnippet(row),
			Tags:      normalizeKeywords(row.Keywords, 3),
			IsNew:     now.Sub(row.CreatedAt) < 24*time.Hour,
			CreatedAt: row.CreatedAt,
		}

		if _, exists := groups[dateKey]; !exists {
			order = append(order, dateKey)
		}
		groups[dateKey] = append(groups[dateKey], entry)

		for _, tag := range normalizeKeywords(row.Keywords, 5) {
			highlightCounts[tag]++
		}
	}

	sort.Slice(order, func(i, j int) bool {
		return order[i] > order[j]
	})

	digests := make([]Digest, 0, len(order))
	for _, key := range order {
		entries := groups[key]
		sort.Slice(entries, func(i, j int) bool {
			return entries[i].CreatedAt.After(entries[j].CreatedAt)
		})
		digests = append(digests, Digest{
			Date:    key,
			Summary: buildDigestSummary(entries),
			Entries: entries,
			Tags:    aggregateTags(entries, 4),
		})
	}

	highlights := collectHighlights(highlightCounts, 5)

	return Response{
		Digests:     digests,
		Highlights:  highlights,
		GeneratedAt: now.Format(time.RFC3339),
	}
}

func buildSnippet(row EpisodeRow) string {
	if row.Summary.Valid {
		if snippet := strings.TrimSpace(row.Summary.String); snippet != "" {
			return snippet
		}
	}
	if title := strings.TrimSpace(row.Title); title != "" {
		return title
	}
	tags := normalizeKeywords(row.Keywords, 3)
	if len(tags) > 0 {
		return "Highlights: " + strings.Join(tags, ", ")
	}
	return "Highlights coming soon."
}

func normalizeKeywords(raw []string, limit int) []string {
	var tags []string
	for _, value := range raw {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if normalized == "" {
			continue
		}
		tags = append(tags, normalized)
		if len(tags) == limit {
			break
		}
	}
	return tags
}

func aggregateTags(entries []Entry, limit int) []string {
	counts := make(map[string]int)
	for _, entry := range entries {
		for _, tag := range entry.Tags {
			counts[tag]++
		}
	}
	return collectHighlights(counts, limit)
}

func collectHighlights(counts map[string]int, limit int) []string {
	type pair struct {
		tag   string
		count int
	}

	var items []pair
	for tag, count := range counts {
		items = append(items, pair{tag: tag, count: count})
	}

	sort.Slice(items, func(i, j int) bool {
		if items[i].count == items[j].count {
			return items[i].tag < items[j].tag
		}
		return items[i].count > items[j].count
	})

	if limit > len(items) {
		limit = len(items)
	}
	highlights := make([]string, 0, limit)
	for i := 0; i < limit; i++ {
		highlights = append(highlights, items[i].tag)
	}
	return highlights
}

func buildDigestSummary(entries []Entry) string {
	var parts []string
	for _, entry := range entries {
		text := strings.TrimSpace(entry.Snippet)
		if text == "" {
			text = strings.TrimSpace(entry.Title)
		}
		if text == "" {
			continue
		}
		parts = append(parts, text)
		if len(parts) == 3 {
			break
		}
	}
	if len(parts) == 0 {
		return ""
	}
	summary := strings.Join(parts, " • ")
	if utf8.RuneCountInString(summary) > digestSummaryLimit {
		runes := []rune(summary)
		summary = string(runes[:digestSummaryLimit-1]) + "…"
	}
	return summary
}
