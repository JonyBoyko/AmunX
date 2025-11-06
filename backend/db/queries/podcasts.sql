-- name: CreatePodcastShow :one
INSERT INTO podcast_shows (
  owner_id,
  title,
  description,
  cover_url,
  rss_slug
) VALUES (
  $1, $2, $3, $4, $5
) RETURNING *;

-- name: GetPodcastShowByID :one
SELECT * FROM podcast_shows WHERE id = $1 LIMIT 1;

-- name: GetPodcastShowBySlug :one
SELECT * FROM podcast_shows WHERE rss_slug = $1 LIMIT 1;

-- name: UpdatePodcastShow :one
UPDATE podcast_shows
SET
  title = COALESCE(sqlc.narg('title'), title),
  description = COALESCE(sqlc.narg('description'), description),
  cover_url = COALESCE(sqlc.narg('cover_url'), cover_url),
  updated_at = now()
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: DeletePodcastShow :exec
DELETE FROM podcast_shows WHERE id = $1;

-- name: ListUserPodcastShows :many
SELECT * FROM podcast_shows
WHERE owner_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: AddPodcastEpisode :exec
INSERT INTO podcast_show_episodes (show_id, audio_id, published_at)
VALUES ($1, $2, $3)
ON CONFLICT DO NOTHING;

-- name: RemovePodcastEpisode :exec
DELETE FROM podcast_show_episodes
WHERE show_id = $1 AND audio_id = $2;

-- name: GetPodcastEpisodes :many
SELECT a.*, pse.published_at
FROM audio_items a
JOIN podcast_show_episodes pse ON pse.audio_id = a.id
WHERE pse.show_id = $1
ORDER BY pse.published_at DESC
LIMIT $2 OFFSET $3;

-- name: GetPodcastEpisode :one
SELECT a.*, pse.published_at
FROM audio_items a
JOIN podcast_show_episodes pse ON pse.audio_id = a.id
WHERE pse.show_id = $1 AND pse.audio_id = $2
LIMIT 1;

