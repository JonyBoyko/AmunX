-- name: CreateAudioItem :one
INSERT INTO audio_items (
  owner_id,
  visibility,
  title,
  description,
  kind,
  duration_sec,
  s3_key,
  audio_url,
  waveform,
  tags,
  share_to_circle_ids,
  parent_audio_id
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
) RETURNING *;

-- name: GetAudioItemByID :one
SELECT * FROM audio_items WHERE id = $1 LIMIT 1;

-- name: UpdateAudioItem :one
UPDATE audio_items
SET
  title = COALESCE(sqlc.narg('title'), title),
  description = COALESCE(sqlc.narg('description'), description),
  visibility = COALESCE(sqlc.narg('visibility'), visibility),
  tags = COALESCE(sqlc.narg('tags'), tags),
  share_to_circle_ids = COALESCE(sqlc.narg('share_to_circle_ids'), share_to_circle_ids),
  updated_at = now()
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: DeleteAudioItem :exec
DELETE FROM audio_items WHERE id = $1;

-- name: ListUserAudioItems :many
SELECT * FROM audio_items
WHERE owner_id = $1
  AND (sqlc.narg('kind')::text IS NULL OR kind = sqlc.narg('kind'))
  AND (sqlc.narg('visibility')::text IS NULL OR visibility = sqlc.narg('visibility'))
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListPublicAudioItems :many
SELECT * FROM audio_items
WHERE visibility = 'public'
  AND (sqlc.narg('kind')::text IS NULL OR kind = sqlc.narg('kind'))
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: GetAudioItemsSharedToCircle :many
SELECT * FROM audio_items
WHERE $1 = ANY(share_to_circle_ids)
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetAudioItemReplies :many
SELECT * FROM audio_items
WHERE parent_audio_id = $1
ORDER BY created_at ASC
LIMIT $2 OFFSET $3;

-- name: LikeAudioItem :exec
INSERT INTO likes (user_id, audio_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: UnlikeAudioItem :exec
DELETE FROM likes
WHERE user_id = $1 AND audio_id = $2;

-- name: SaveAudioItem :exec
INSERT INTO saves (user_id, audio_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: UnsaveAudioItem :exec
DELETE FROM saves
WHERE user_id = $1 AND audio_id = $2;

-- name: GetAudioItemLikesCount :one
SELECT COUNT(*) FROM likes WHERE audio_id = $1;

-- name: GetAudioItemSavesCount :one
SELECT COUNT(*) FROM saves WHERE audio_id = $1;

-- name: IsAudioItemLiked :one
SELECT EXISTS(
  SELECT 1 FROM likes
  WHERE user_id = $1 AND audio_id = $2
);

-- name: IsAudioItemSaved :one
SELECT EXISTS(
  SELECT 1 FROM saves
  WHERE user_id = $1 AND audio_id = $2
);

-- name: GetUserSavedAudioItems :many
SELECT a.*
FROM audio_items a
JOIN saves s ON s.audio_id = a.id
WHERE s.user_id = $1
ORDER BY s.created_at DESC
LIMIT $2 OFFSET $3;

