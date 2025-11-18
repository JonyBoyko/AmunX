package smartinbox

import (
	"context"
	"database/sql"
	"errors"
)

// FetchEpisodeRows pulls recent public episodes with summaries/keywords.
func FetchEpisodeRows(ctx context.Context, db *sql.DB, limit int) ([]EpisodeRow, error) {
	if db == nil {
		return nil, errors.New("smart inbox: db is nil")
	}
	if limit <= 0 {
		limit = 60
	}

	const stmt = `
SELECT e.id,
       COALESCE(e.title, '') AS title,
       e.author_id,
       COALESCE(s.tldr, '') AS summary,
       COALESCE(s.keywords, ARRAY[]::text[]) AS keywords,
       e.created_at
  FROM episodes e
  LEFT JOIN summaries s ON s.episode_id = e.id
 WHERE e.status = 'public'
   AND e.visibility = 'public'
 ORDER BY e.created_at DESC
 LIMIT $1`

	rows, err := db.QueryContext(ctx, stmt, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []EpisodeRow
	for rows.Next() {
		var row EpisodeRow
		if err := rows.Scan(&row.ID, &row.Title, &row.AuthorID, &row.Summary, &row.Keywords, &row.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, row)
	}
	return items, rows.Err()
}
