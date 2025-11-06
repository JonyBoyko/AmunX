package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/amunx/backend/internal/app"
)

// SearchResultResponse represents a search result
type SearchResultResponse struct {
	AudioID    string        `json:"audio_id"`
	Owner      UserResponse  `json:"owner"`
	Title      string        `json:"title"`
	DurationSec int          `json:"duration_sec"`
	Snippet    string        `json:"snippet"` // HTML with <b> tags for highlights
	MatchScore float64       `json:"match_score"`
	Tags       []string      `json:"tags"`
	CreatedAt  string        `json:"created_at"`
}

// SearchResponse represents the search API response
type SearchResponse struct {
	Results    []SearchResultResponse `json:"results"`
	Total      int                    `json:"total"`
	SearchType string                 `json:"search_type"` // hybrid, text, vector
}

// SearchAudio searches audio items by text and semantic similarity (GET /search)
func SearchAudio(w http.ResponseWriter, r *http.Request, deps *app.App) {
	query := r.URL.Query().Get("q")
	if query == "" {
		WriteError(w, http.StatusBadRequest, "invalid_request", "query parameter 'q' is required")
		return
	}

	limit := getIntQueryParam(r, "limit", 20)
	offset := getIntQueryParam(r, "offset", 0)
	if limit > 100 {
		limit = 100
	}

	userID := getUserID(r) // May be nil for anonymous

	_ = userID
	_ = offset

	// TODO: Hybrid search implementation:
	// 1. Full-text search on transcripts using PostgreSQL tsvector
	//    - Use ts_rank for scoring
	//    - Use ts_headline for snippet generation
	//
	// 2. Vector similarity search on embeddings using pgvector
	//    - First, generate embedding for query using OpenAI API
	//    - Then search: SELECT * FROM embeddings ORDER BY vector <=> query_embedding LIMIT 20
	//    - Use cosine similarity (1 - distance)
	//
	// 3. Merge and rank results
	//    - Combine scores: 0.6 * text_score + 0.4 * vector_score
	//    - Deduplicate by audio_id (take highest score)
	//    - Sort by combined score DESC
	//
	// 4. Apply privacy filters
	//    - Only show public items
	//    - Or items shared to circles user is a member of
	//    - Or user's own private items

	// Mock response
	results := []SearchResultResponse{
		{
			AudioID:     "uuid-1",
			Owner: UserResponse{
				ID:          "owner-uuid",
				DisplayName: "John Startup",
			},
			Title:       "Startup Growth Strategies",
			DurationSec: 180,
			Snippet:     "...discussing <b>startup</b> <b>growth</b> tactics and how to scale...",
			MatchScore:  0.85,
			Tags:        []string{"startup", "business", "growth"},
			CreatedAt:   "2025-01-06T10:00:00Z",
		},
	}

	response := SearchResponse{
		Results:    results,
		Total:      1,
		SearchType: "hybrid",
	}

	WriteJSON(w, http.StatusOK, response)
}

// registerSearchRoutes registers routes for search
func registerSearchRoutes(r chi.Router, deps *app.App) {
	r.Get("/search", func(w http.ResponseWriter, req *http.Request) {
		SearchAudio(w, req, deps)
	})
}


