package http

import (
	"context"
	"database/sql"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
)

// ExploreCardResponse represents a card in the Explore feed
type ExploreCardResponse struct {
	ID              string              `json:"id"`
	Kind            string              `json:"kind"`
	ParentAudioID   *string             `json:"parent_audio_id,omitempty"`
	Owner           UserResponse        `json:"owner"`
	DurationSec     int                 `json:"duration_sec"`
	PreviewSentence string              `json:"preview_sentence"`
	Title           string              `json:"title,omitempty"`
	Quote           string              `json:"quote,omitempty"`
	Tags            []string            `json:"tags"`
	WaveformPeaks   []float64           `json:"waveform_peaks,omitempty"`
	AudioURL        string              `json:"audio_url"`
	CreatedAt       string              `json:"created_at"`
	Stats           *AudioStatsResponse `json:"stats,omitempty"`
	RankScore       float64             `json:"rank_score,omitempty"`
	createdAtTime   time.Time           `json:"-"`
}

// ExploreFeedResponse represents the Explore feed response
type ExploreFeedResponse struct {
	Cards      []ExploreCardResponse `json:"cards"`
	NextCursor *string               `json:"next_cursor"`
	HasMore    bool                  `json:"has_more"`
}

// RankingWeights defines the weights for the ranking algorithm
type RankingWeights struct {
	Recency         float64
	PreviewFinished float64
	Save            float64
	FollowAuthor    float64
}

var defaultRankingWeights = RankingWeights{
	Recency:         0.6,
	PreviewFinished: 0.2,
	Save:            0.15,
	FollowAuthor:    0.05,
}

func GetExploreFeed(w http.ResponseWriter, r *http.Request, deps *app.App) {
	limit := getIntQueryParam(r, "limit", 20)
	if limit > 50 {
		limit = 50
	}

	filters := parseExploreFilters(r)
	cards, err := queryExploreFeed(r.Context(), deps.DB, filters, limit+1)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "explore_feed_failed", err.Error())
		return
	}

	var nextCursor *string
	if len(cards) > limit {
		cursor := cards[limit].createdAtTime.Format(time.RFC3339)
		nextCursor = &cursor
		cards = cards[:limit]
	}

	cards = applyDiversityConstraint(cards, limit)

	WriteJSON(w, http.StatusOK, ExploreFeedResponse{
		Cards:      cards,
		NextCursor: nextCursor,
		HasMore:    nextCursor != nil,
	})
}

func calculateRankScore(
	createdAt time.Time,
	impressions, previewsFinished, saves, follows int64,
	weights RankingWeights,
) float64 {
	ageHours := time.Since(createdAt).Hours()
	recencyScore := math.Exp(-ageHours / 72.0)

	previewRate := 0.0
	saveRate := 0.0
	followRate := 0.0
	if impressions > 0 {
		previewRate = float64(previewsFinished) / float64(impressions)
		saveRate = float64(saves) / float64(impressions)
		followRate = float64(follows) / float64(impressions)
	}

	score := weights.Recency*recencyScore +
		weights.PreviewFinished*previewRate +
		weights.Save*saveRate +
		weights.FollowAuthor*followRate
	return score
}

func applyDiversityConstraint(cards []ExploreCardResponse, topN int) []ExploreCardResponse {
	if len(cards) <= topN {
		topN = len(cards)
	}
	authorCounts := make(map[string]int)
	result := make([]ExploreCardResponse, 0, len(cards))
	for _, card := range cards {
		if len(result) >= topN {
			break
		}
		if authorCounts[card.Owner.ID] < 2 {
			result = append(result, card)
			authorCounts[card.Owner.ID]++
		}
	}
	if len(cards) > topN {
		result = append(result, cards[topN:]...)
	}
	return result
}

func registerExploreRoutes(r chi.Router, deps *app.App) {
	r.Get("/explore", func(w http.ResponseWriter, req *http.Request) {
		GetExploreFeed(w, req, deps)
	})
}

type exploreFilters struct {
	Tags      []string
	TopicIDs  []uuid.UUID
	MinLength int
	MaxLength int
	Cursor    *time.Time
}

func parseExploreFilters(r *http.Request) exploreFilters {
	q := r.URL.Query()

	tagInputs := make([]string, 0, len(q["tags"])+len(q["topics"])+len(q["tag"]))
	tagInputs = append(tagInputs, q["tags"]...)
	tagInputs = append(tagInputs, q["tag"]...)
	if raw := q.Get("topics"); raw != "" {
		tagInputs = append(tagInputs, raw)
	}
	tags := normalizeExploreTags(tagInputs)

	var minLen, maxLen int
	if raw := q.Get("len"); raw != "" {
		parts := strings.Split(raw, "..")
		if len(parts) == 2 {
			if v, err := strconv.Atoi(strings.TrimSpace(parts[0])); err == nil && v > 0 {
				minLen = v
			}
			if v, err := strconv.Atoi(strings.TrimSpace(parts[1])); err == nil && v > 0 {
				maxLen = v
			}
		}
	}

	var cursor *time.Time
	if raw := q.Get("cursor"); raw != "" {
		if parsed, err := time.Parse(time.RFC3339, raw); err == nil {
			cursor = &parsed
		}
	}

	topics := parseTopicIDsFilter(q)

	return exploreFilters{
		Tags:      tags,
		TopicIDs:  topics,
		MinLength: minLen,
		MaxLength: maxLen,
		Cursor:    cursor,
	}
}

func queryExploreFeed(ctx context.Context, db *sql.DB, filters exploreFilters, limit int) ([]ExploreCardResponse, error) {
	query := `
WITH reaction_totals AS (
    SELECT audio_id,
           COUNT(*) FILTER (WHERE type = 'like') AS likes,
           COUNT(*) FILTER (WHERE type IN ('save','bookmark')) AS bookmarks
      FROM reactions
     GROUP BY audio_id
),
comment_totals AS (
    SELECT audio_id, COUNT(*) AS comments
      FROM comments
     GROUP BY audio_id
)
SELECT e.id,
       e.owner_id,
       COALESCE(NULLIF(u.display_name, ''), split_part(u.email, '@', 1)) AS display_name,
       COALESCE(NULLIF(u.avatar, ''), '') AS avatar,
       COALESCE(e.duration_sec, 0) AS duration,
       COALESCE(s.tldr, '') AS summary,
       COALESCE(s.keywords, ARRAY[]::text[]) AS keywords,
       COALESCE(e.audio_url, '') AS audio_url,
       COALESCE(e.title, '') AS title,
       e.created_at,
       COALESCE(rt.likes, 0) AS likes,
       COALESCE(rt.bookmarks, 0) AS saves,
       COALESCE(ct.comments, 0) AS comments
  FROM audio_items e
  JOIN users u ON u.id = e.owner_id
  LEFT JOIN summaries s ON s.audio_id = e.id
  LEFT JOIN reaction_totals rt ON rt.audio_id = e.id
  LEFT JOIN comment_totals ct ON ct.audio_id = e.id
 WHERE e.visibility = 'public'
   AND NOT (u.plan = 'free' AND COALESCE(e.duration_sec, 0) <= $1 AND e.created_at < NOW() - INTERVAL '24 hours')
`
	args := []any{shortStoryDurationThreshold}
	idx := 2

	if filters.MinLength > 0 {
		query += fmt.Sprintf(" AND COALESCE(e.duration_sec, 0) >= $%d", idx)
		args = append(args, filters.MinLength)
		idx++
	}
	if filters.MaxLength > 0 {
		query += fmt.Sprintf(" AND COALESCE(e.duration_sec, 0) <= $%d", idx)
		args = append(args, filters.MaxLength)
		idx++
	}
	if filters.Cursor != nil {
		query += fmt.Sprintf(" AND e.created_at < $%d", idx)
		args = append(args, *filters.Cursor)
		idx++
	}
	if len(filters.TopicIDs) > 0 {
		query += fmt.Sprintf(" AND e.topic_id = ANY($%d)", idx)
		args = append(args, pq.Array(uuidStrings(filters.TopicIDs)))
		idx++
	}
	if len(filters.Tags) > 0 {
		query += fmt.Sprintf(` AND EXISTS (
            SELECT 1 FROM unnest(COALESCE(s.keywords, ARRAY[]::text[])) kw
             WHERE lower(kw) = ANY($%d)
        )`, idx)
		args = append(args, pq.Array(filters.Tags))
		idx++
	}

	query += " ORDER BY e.created_at DESC LIMIT $" + strconv.Itoa(idx)
	args = append(args, limit)

	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []ExploreCardResponse
	for rows.Next() {
		var (
			id        uuid.UUID
			authorID  uuid.UUID
			display   string
			avatar    string
			duration  int
			summary   string
			keywords  pq.StringArray
			audioURL  string
			title     string
			createdAt time.Time
			likes     int64
			saves     int64
			comments  int64
		)
		if err := rows.Scan(&id, &authorID, &display, &avatar, &duration, &summary, &keywords, &audioURL, &title, &createdAt, &likes, &saves, &comments); err != nil {
			return nil, err
		}
		preview := strings.TrimSpace(summary)
		if preview == "" {
			preview = strings.TrimSpace(title)
		}
		tags := append([]string(nil), []string(keywords)...)
		impressions := deriveImpressions(likes, saves, comments)
		previews := comments
		follows := int64(0)
		plays := derivePlayCount(impressions, likes, comments)

		card := ExploreCardResponse{
			ID:              id.String(),
			Kind:            "audio_item",
			Owner:           UserResponse{ID: authorID.String(), DisplayName: display, AvatarURL: avatar},
			DurationSec:     duration,
			PreviewSentence: preview,
			Title:           strings.TrimSpace(title),
			Tags:            tags,
			AudioURL:        audioURL,
			CreatedAt:       createdAt.Format(time.RFC3339),
			createdAtTime:   createdAt,
			Stats: &AudioStatsResponse{
				Likes: likes,
				Saves: saves,
				Plays: plays,
			},
		}
		card.RankScore = calculateRankScore(createdAt, impressions, previews, saves, follows, defaultRankingWeights)
		cards = append(cards, card)
	}
	return cards, rows.Err()
}

func normalizeExploreTags(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	seen := make(map[string]struct{})
	var tags []string
	for _, raw := range values {
		for _, part := range strings.Split(raw, ",") {
			trimmed := strings.ToLower(strings.TrimSpace(strings.TrimPrefix(part, "#")))
			if trimmed == "" {
				continue
			}
			if _, exists := seen[trimmed]; exists {
				continue
			}
			seen[trimmed] = struct{}{}
			tags = append(tags, trimmed)
		}
	}
	return tags
}

func parseTopicIDsFilter(q map[string][]string) []uuid.UUID {
	var ids []uuid.UUID
	seen := make(map[uuid.UUID]struct{})
	add := func(value string) {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			return
		}
		id, err := uuid.Parse(trimmed)
		if err != nil {
			return
		}
		if _, ok := seen[id]; ok {
			return
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}

	for _, raw := range q["topic_id"] {
		add(raw)
	}
	for _, raw := range q["topic_ids"] {
		for _, part := range strings.Split(raw, ",") {
			add(part)
		}
	}
	return ids
}

func uuidStrings(ids []uuid.UUID) []string {
	out := make([]string, len(ids))
	for i, id := range ids {
		out[i] = id.String()
	}
	return out
}

func deriveImpressions(likes, saves, comments int64) int64 {
	base := likes*4 + saves*6 + comments*3
	if base < 0 {
		base = 0
	}
	return base
}

func derivePlayCount(impressions, likes, comments int64) int64 {
	plays := impressions / 2
	min := likes + comments
	if plays < min {
		plays = min
	}
	if plays < 0 {
		plays = 0
	}
	return plays
}
