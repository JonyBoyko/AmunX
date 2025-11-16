package http

import (
	"math"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/amunx/backend/internal/app"
)

// ExploreCardResponse represents a card in the Explore feed
type ExploreCardResponse struct {
	ID              string              `json:"id"`
	Kind            string              `json:"kind"` // audio_item or clip
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
	RankScore       float64             `json:"rank_score,omitempty"` // For debugging
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

// Default ranking weights (can be tuned)
var defaultRankingWeights = RankingWeights{
	Recency:         0.6,
	PreviewFinished: 0.2,
	Save:            0.15,
	FollowAuthor:    0.05,
}

// GetExploreFeed returns the Explore feed with ranked cards (GET /explore)
func GetExploreFeed(w http.ResponseWriter, r *http.Request, deps *app.App) {
	// Query params
	cursor := r.URL.Query().Get("cursor")
	topics := r.URL.Query().Get("topics") // Comma-separated tags
	city := r.URL.Query().Get("city")
	lenRange := r.URL.Query().Get("len") // e.g., "30..120"
	limit := getIntQueryParam(r, "limit", 20)
	if limit > 50 {
		limit = 50
	}

	userID := getUserID(r) // May be nil for anonymous users

	_ = cursor
	_ = topics
	_ = city
	_ = lenRange
	_ = userID

	// TODO: Fetch public audio_items and clips from database
	// TODO: Apply filters (topics, city, duration range)
	// TODO: Calculate rank score for each item
	// TODO: Sort by rank score DESC
	// TODO: Apply diversity constraint (max 2 items per author in top 20)
	// TODO: Paginate with cursor

	// Mock response with sample cards
	cards := []ExploreCardResponse{
		{
			ID:   uuid.New().String(),
			Kind: "audio_item",
			Owner: UserResponse{
				ID:          uuid.New().String(),
				DisplayName: "Jane Smith",
				AvatarURL:   "https://cdn.moweton.com/avatars/jane.jpg",
			},
			DurationSec:     45,
			PreviewSentence: "A quick tip about React hooks",
			Tags:            []string{"react", "javascript"},
			AudioURL:        "https://cdn.moweton.com/audio/sample1.mp3",
			CreatedAt:       time.Now().Add(-2 * time.Hour).Format(time.RFC3339),
			Stats: &AudioStatsResponse{
				Likes: 15,
				Saves: 8,
				Plays: 200,
			},
			RankScore: 0.85,
		},
		{
			ID:   uuid.New().String(),
			Kind: "clip",
			Owner: UserResponse{
				ID:          uuid.New().String(),
				DisplayName: "John Doe",
				AvatarURL:   "https://cdn.moweton.com/avatars/john.jpg",
			},
			DurationSec: 15,
			Title:       "Best Quote",
			Quote:       "Ship it!",
			AudioURL:    "https://cdn.moweton.com/audio/clip1.mp3",
			CreatedAt:   time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
			RankScore:   0.78,
		},
	}

	response := ExploreFeedResponse{
		Cards:      cards,
		NextCursor: nil,
		HasMore:    false,
	}

	WriteJSON(w, http.StatusOK, response)
}

// calculateRankScore computes the ranking score for an audio item
// Based on spec: score = w_recency*exp(-age_hours/72) + w_preview*rate_preview_finished + w_save*rate_save + w_follow*rate_follow_author
func calculateRankScore(
	createdAt time.Time,
	impressions, previewsFinished, saves, follows int64,
	weights RankingWeights,
) float64 {
	now := time.Now()
	ageHours := now.Sub(createdAt).Hours()

	// Recency score: exponential decay with half-life of ~72 hours
	recencyScore := math.Exp(-ageHours / 72.0)

	// Engagement rates (avoid division by zero)
	previewRate := 0.0
	if impressions > 0 {
		previewRate = float64(previewsFinished) / float64(impressions)
	}

	saveRate := 0.0
	if impressions > 0 {
		saveRate = float64(saves) / float64(impressions)
	}

	followRate := 0.0
	if impressions > 0 {
		followRate = float64(follows) / float64(impressions)
	}

	// Weighted sum
	score := weights.Recency*recencyScore +
		weights.PreviewFinished*previewRate +
		weights.Save*saveRate +
		weights.FollowAuthor*followRate

	return score
}

// applyDiversityConstraint ensures max 2 items per author in top N results
func applyDiversityConstraint(cards []ExploreCardResponse, topN int) []ExploreCardResponse {
	if len(cards) <= topN {
		topN = len(cards)
	}

	authorCounts := make(map[string]int)
	result := []ExploreCardResponse{}

	for i := 0; i < len(cards) && len(result) < topN; i++ {
		authorID := cards[i].Owner.ID
		if authorCounts[authorID] < 2 {
			result = append(result, cards[i])
			authorCounts[authorID]++
		}
	}

	// Add remaining cards after top N
	if len(cards) > topN {
		result = append(result, cards[topN:]...)
	}

	return result
}

// registerExploreRoutes registers routes for Explore feed
func registerExploreRoutes(r chi.Router, deps *app.App) {
	r.Get("/explore", func(w http.ResponseWriter, req *http.Request) {
		GetExploreFeed(w, req, deps)
	})
}


