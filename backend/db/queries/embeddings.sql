-- name: CreateEmbedding :one
INSERT INTO embeddings (
  audio_id,
  chunk_index,
  vector,
  text_chunk
) VALUES (
  $1, $2, $3, $4
) RETURNING *;

-- name: GetEmbeddingsByAudioID :many
SELECT * FROM embeddings
WHERE audio_id = $1
ORDER BY chunk_index ASC;

-- name: DeleteEmbeddingsByAudioID :exec
DELETE FROM embeddings WHERE audio_id = $1;

-- Note: Vector similarity search needs to be done with raw SQL or pgx
-- because sqlc doesn't support vector operators well yet.
-- Example query (use in code):
-- SELECT audio_id, text_chunk, 1 - (vector <=> $1) as similarity
-- FROM embeddings
-- ORDER BY vector <=> $1
-- LIMIT $2;

