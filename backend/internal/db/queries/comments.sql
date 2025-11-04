-- name: CreateComment :one
INSERT INTO comments (episode_id, author_id, text)
VALUES ($1, $2, $3)
RETURNING *;

-- name: ListCommentsByEpisode :many
SELECT *
FROM comments
WHERE episode_id = $1
ORDER BY created_at ASC
LIMIT $2 OFFSET $3;

