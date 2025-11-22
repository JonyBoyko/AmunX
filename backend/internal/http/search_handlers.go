package http

import (
	"context"
	"database/sql"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/lib/pq"

	"github.com/amunx/backend/internal/app"
)

// SearchResultResponse represents a search result
type SearchResultResponse struct {
	AudioID     string       `json:"audio_id"`
	Owner       UserResponse `json:"owner"`
	Title       string       `json:"title"`
	DurationSec int          `json:"duration_sec"`
	Snippet     string       `json:"snippet"` // HTML with <b> tags for highlights
	MatchScore  float64      `json:"match_score"`
	Tags        []string     `json:"tags"`
	CreatedAt   string       `json:"created_at"`
}

// SearchResponse represents the search API response
type SearchResponse struct {
	Results    []SearchResultResponse `json:"results"`
	Total      int                    `json:"total"`
	SearchType string                 `json:"search_type"` // hybrid, text, vector
}

// SearchAudio searches audio items by text and semantic similarity (GET /search)
func SearchAudio(w http.ResponseWriter, r *http.Request, deps *app.App) {
	query := strings.TrimSpace(r.URL.Query().Get("q"))
	if len(query) < 2 {
		WriteError(w, http.StatusBadRequest, "invalid_request", "query parameter 'q' must be at least 2 characters")
		return
	}

	limit := getIntQueryParam(r, "limit", 20)
	if limit <= 0 {
		limit = 20
	}
	if limit > 50 {
		limit = 50
	}
	offset := getIntQueryParam(r, "offset", 0)
	if offset < 0 {
		offset = 0
	}

	ctx := r.Context()
	results, total, err := executeTextSearch(ctx, deps.DB, query, limit, offset)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "search_failed", err.Error())
		return
	}

	searchType := "text"
	if total == 0 {
		results, total, err = executeFallbackSearch(ctx, deps.DB, query, limit, offset)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "search_failed", err.Error())
			return
		}
		if total > 0 {
			searchType = "text_fallback"
		}
	}

	response := SearchResponse{
		Results:    results,
		Total:      total,
		SearchType: searchType,
	}

	WriteJSON(w, http.StatusOK, response)
}

// registerSearchRoutes registers routes for search
func registerSearchRoutes(r chi.Router, deps *app.App) {
	r.Get("/search", func(w http.ResponseWriter, req *http.Request) {
		SearchAudio(w, req, deps)
	})
}

func executeTextSearch(ctx context.Context, db *sql.DB, query string, limit, offset int) ([]SearchResultResponse, int, error) {
	var total int
	if err := db.QueryRowContext(ctx, textSearchCountSQL, query).Scan(&total); err != nil {
		return nil, 0, err
	}
	if total == 0 {
		return nil, 0, nil
	}

	rows, err := db.QueryContext(ctx, textSearchSelectSQL, query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	results := make([]SearchResultResponse, 0, limit)
	for rows.Next() {
		var (
			audioID   uuid.UUID
			ownerID   uuid.UUID
			title     string
			duration  int
			createdAt time.Time
			keywords  pq.StringArray
			summary   string
			rank      float64
			snippet   sql.NullString
			display   string
			avatar    string
		)
		if err := rows.Scan(&audioID, &ownerID, &title, &duration, &createdAt, &keywords, &summary, &rank, &snippet, &display, &avatar); err != nil {
			return nil, 0, err
		}
		snippetText := strings.TrimSpace(snippet.String)
		if !snippet.Valid || snippetText == "" {
			snippetText = buildSearchSnippet(summary, title)
		}
		tags := append([]string(nil), []string(keywords)...)
		results = append(results, SearchResultResponse{
			AudioID:     audioID.String(),
			Owner:       UserResponse{ID: ownerID.String(), DisplayName: display, AvatarURL: avatar},
			Title:       strings.TrimSpace(title),
			DurationSec: duration,
			Snippet:     snippetText,
			MatchScore:  rank,
			Tags:        tags,
			CreatedAt:   createdAt.Format(time.RFC3339),
		})
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return results, total, nil
}

func executeFallbackSearch(ctx context.Context, db *sql.DB, query string, limit, offset int) ([]SearchResultResponse, int, error) {
	pattern := "%" + escapeILikePattern(query) + "%"
	var total int
	if err := db.QueryRowContext(ctx, fallbackSearchCountSQL, pattern).Scan(&total); err != nil {
		return nil, 0, err
	}
	if total == 0 {
		return nil, 0, nil
	}

	rows, err := db.QueryContext(ctx, fallbackSearchSelectSQL, pattern, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	results := make([]SearchResultResponse, 0, limit)
	index := 0
	for rows.Next() {
		var (
			audioID   uuid.UUID
			ownerID   uuid.UUID
			title     string
			duration  int
			createdAt time.Time
			keywords  pq.StringArray
			summary   string
			display   string
			avatar    string
		)
		if err := rows.Scan(&audioID, &ownerID, &title, &duration, &createdAt, &keywords, &summary, &display, &avatar); err != nil {
			return nil, 0, err
		}
		tags := append([]string(nil), []string(keywords)...)
		score := 0.3 - 0.01*float64(index)
		if score < 0.1 {
			score = 0.1
		}
		results = append(results, SearchResultResponse{
			AudioID:     audioID.String(),
			Owner:       UserResponse{ID: ownerID.String(), DisplayName: display, AvatarURL: avatar},
			Title:       strings.TrimSpace(title),
			DurationSec: duration,
			Snippet:     buildSearchSnippet(summary, title),
			MatchScore:  score,
			Tags:        tags,
			CreatedAt:   createdAt.Format(time.RFC3339),
		})
		index++
	}
	if err := rows.Err(); err != nil {
		return nil, 0, err
	}
	return results, total, nil
}

func buildSearchSnippet(summary, title string) string {
	text := strings.TrimSpace(summary)
	if text == "" {
		text = strings.TrimSpace(title)
	}
	if text == "" {
		return ""
	}
	const maxLen = 220
	runes := []rune(text)
	if len(runes) <= maxLen {
		return text
	}
	return string(runes[:maxLen]) + "…"
}

func escapeILikePattern(value string) string {
	replacer := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return replacer.Replace(value)
}

const searchDocumentsCTE = `
WITH search_query AS (SELECT plainto_tsquery('english', $1) AS query),
docs AS (
    SELECT e.id,
           e.owner_id AS author_id,
           COALESCE(e.title, '') AS title,
           COALESCE(e.duration_sec, 0) AS duration_sec,
           e.created_at,
           COALESCE(s.keywords, ARRAY[]::text[]) AS keywords,
           COALESCE(s.tldr, '') AS summary,
           setweight(to_tsvector('english', COALESCE(e.title, '')), 'A') ||
           setweight(to_tsvector('english', COALESCE(s.tldr, '')), 'B') ||
           setweight(to_tsvector('english', array_to_string(COALESCE(s.keywords, ARRAY[]::text[]), ' ')), 'C') AS document
      FROM audio_items e
      LEFT JOIN summaries s ON s.audio_id = e.id
     WHERE e.visibility = 'public'
)
`

const textSearchSelectSQL = searchDocumentsCTE + `
SELECT d.id,
       d.author_id,
       d.title,
       d.duration_sec,
       d.created_at,
       d.keywords,
       d.summary,
       ts_rank_cd(d.document, search_query.query) AS rank,
       ts_headline(
           'english',
           NULLIF(d.summary, ''),
           search_query.query,
           'MaxFragments=2, MinWords=5, MaxWords=18, StartSel=<b>, StopSel=</b>'
       ) AS snippet,
       COALESCE(NULLIF(u.display_name, ''), split_part(u.email, '@', 1)) AS display_name,
       COALESCE(u.avatar, '') AS avatar
  FROM search_query, docs d
  JOIN users u ON u.id = d.author_id
 WHERE d.document @@ search_query.query
 ORDER BY rank DESC, d.created_at DESC
 LIMIT $2 OFFSET $3;
`

const textSearchCountSQL = searchDocumentsCTE + `
SELECT COUNT(*)
  FROM search_query, docs d
 WHERE d.document @@ search_query.query;
`

const fallbackSearchSelectSQL = `
SELECT e.id,
       e.owner_id AS author_id,
       COALESCE(e.title, '') AS title,
       COALESCE(e.duration_sec, 0) AS duration_sec,
       e.created_at,
       COALESCE(s.keywords, ARRAY[]::text[]) AS keywords,
       COALESCE(s.tldr, '') AS summary,
       COALESCE(NULLIF(u.display_name, ''), split_part(u.email, '@', 1)) AS display_name,
       COALESCE(u.avatar, '') AS avatar
  FROM audio_items e
  JOIN users u ON u.id = e.owner_id
  LEFT JOIN summaries s ON s.audio_id = e.id
 WHERE e.visibility = 'public'
   AND (
        COALESCE(e.title, '') ILIKE $1 ESCAPE '\'
        OR COALESCE(s.tldr, '') ILIKE $1 ESCAPE '\'
   )
 ORDER BY e.created_at DESC
 LIMIT $2 OFFSET $3;
`

const fallbackSearchCountSQL = `
SELECT COUNT(*)
  FROM audio_items e
  LEFT JOIN summaries s ON s.audio_id = e.id
 WHERE e.visibility = 'public'
   AND (
        COALESCE(e.title, '') ILIKE $1 ESCAPE '\'
        OR COALESCE(s.tldr, '') ILIKE $1 ESCAPE '\'
   );
`
