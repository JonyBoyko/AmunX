-- name: CreateEpisode :one
INSERT INTO episodes (id, author_id, topic_id, visibility, mask, quality, duration_sec, storage_key)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id, status, storage_key, created_at;

-- name: UpdateEpisodeStatus :one
UPDATE episodes
SET status = $2,
    status_changed_at = now(),
    updated_at = now(),
    published_at = CASE WHEN $2 = 'public' THEN now() ELSE published_at END
WHERE id = $1
RETURNING id, status, status_changed_at, published_at;

-- name: ListPublicEpisodes :many
SELECT *
FROM episodes
WHERE status = 'public'
ORDER BY published_at DESC
LIMIT $1 OFFSET $2;

