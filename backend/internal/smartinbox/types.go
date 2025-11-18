package smartinbox

import (
	"database/sql"
	"time"

	"github.com/lib/pq"
)

// Entry represents a single Smart Inbox row in the final response.
type Entry struct {
	EpisodeID string    `json:"episode_id"`
	Title     string    `json:"title"`
	AuthorID  string    `json:"author_id"`
	Snippet   string    `json:"snippet"`
	Tags      []string  `json:"tags"`
	IsNew     bool      `json:"is_new"`
	CreatedAt time.Time `json:"created_at"`
}

// Digest groups Smart Inbox entries per day with top tags.
type Digest struct {
	Date    string   `json:"date"`
	Summary string   `json:"summary"`
	Entries []Entry  `json:"entries"`
	Tags    []string `json:"tags"`
}

// Response is the payload returned to clients.
type Response struct {
	Digests     []Digest `json:"digests"`
	Highlights  []string `json:"highlights"`
	GeneratedAt string   `json:"generated_at"`
}

// EpisodeRow mirrors the SQL query used to build Smart Inbox digests.
type EpisodeRow struct {
	ID        string
	Title     string
	AuthorID  string
	Summary   sql.NullString
	Keywords  pq.StringArray
	CreatedAt time.Time
}
