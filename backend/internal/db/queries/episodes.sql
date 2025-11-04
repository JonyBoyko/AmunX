-- name: CreateEpisode :one
INSERT INTO episodes (author_id, topic_id, visibility, status, title, duration_sec, quality, mask, is_live)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: UpdateEpisodeStatus :one
UPDATE episodes
SET status = $2,
    published_at = CASE WHEN $2 = 'public' THEN now() ELSE published_at END
WHERE id = $1
RETURNING *;

-- name: ListPublicEpisodes :many
SELECT *
FROM episodes
WHERE status = 'public'
ORDER BY published_at DESC
LIMIT $1 OFFSET $2;

