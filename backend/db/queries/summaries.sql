-- name: CreateSummary :one
INSERT INTO summaries (
  audio_id,
  preview_sentence,
  tldr,
  chapters,
  keywords,
  mood
) VALUES (
  $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetSummary :one
SELECT * FROM summaries WHERE audio_id = $1 LIMIT 1;

-- name: UpdateSummary :one
UPDATE summaries
SET
  preview_sentence = COALESCE(sqlc.narg('preview_sentence'), preview_sentence),
  tldr = COALESCE(sqlc.narg('tldr'), tldr),
  chapters = COALESCE(sqlc.narg('chapters'), chapters),
  keywords = COALESCE(sqlc.narg('keywords'), keywords),
  mood = COALESCE(sqlc.narg('mood'), mood)
WHERE audio_id = sqlc.arg('audio_id')
RETURNING *;

-- name: DeleteSummary :exec
DELETE FROM summaries WHERE audio_id = $1;

