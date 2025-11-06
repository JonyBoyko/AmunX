-- name: CreateTranscript :one
INSERT INTO transcripts (
  audio_id,
  text,
  lang,
  words
) VALUES (
  $1, $2, $3, $4
) RETURNING *;

-- name: GetTranscript :one
SELECT * FROM transcripts WHERE audio_id = $1 LIMIT 1;

-- name: UpdateTranscript :one
UPDATE transcripts
SET
  text = $2,
  lang = $3,
  words = $4
WHERE audio_id = $1
RETURNING *;

-- name: DeleteTranscript :exec
DELETE FROM transcripts WHERE audio_id = $1;

-- name: SearchTranscripts :many
SELECT 
  t.audio_id,
  t.text,
  t.lang,
  ts_rank(to_tsvector('english', t.text), plainto_tsquery('english', $1)) as rank,
  ts_headline('english', t.text, plainto_tsquery('english', $1), 
    'MaxWords=50, MinWords=25, ShortWord=3, HighlightAll=false, MaxFragments=3') as snippet
FROM transcripts t
WHERE to_tsvector('english', t.text) @@ plainto_tsquery('english', $1)
ORDER BY rank DESC
LIMIT $2 OFFSET $3;

