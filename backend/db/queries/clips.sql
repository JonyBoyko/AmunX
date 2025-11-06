-- name: CreateClip :one
INSERT INTO clips (
  audio_id,
  start_sec,
  end_sec,
  title,
  quote
) VALUES (
  $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetClipByID :one
SELECT * FROM clips WHERE id = $1 LIMIT 1;

-- name: GetClipsByAudioID :many
SELECT * FROM clips
WHERE audio_id = $1
ORDER BY start_sec ASC;

-- name: ListRecentClips :many
SELECT * FROM clips
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: DeleteClip :exec
DELETE FROM clips WHERE id = $1;

-- name: DeleteClipsByAudioID :exec
DELETE FROM clips WHERE audio_id = $1;

