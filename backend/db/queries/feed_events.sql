-- name: RecordFeedEvent :exec
INSERT INTO feed_events (
  user_id,
  audio_id,
  event,
  meta
) VALUES (
  $1, $2, $3, $4
);

-- name: GetAudioItemEvents :many
SELECT * FROM feed_events
WHERE audio_id = $1
  AND (sqlc.narg('event')::text IS NULL OR event = sqlc.narg('event'))
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetUserEvents :many
SELECT * FROM feed_events
WHERE user_id = $1
  AND (sqlc.narg('event')::text IS NULL OR event = sqlc.narg('event'))
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetAudioItemEventCounts :one
SELECT
  COUNT(*) FILTER (WHERE event = 'impression') as impressions,
  COUNT(*) FILTER (WHERE event = 'preview_finished') as previews_finished,
  COUNT(*) FILTER (WHERE event = 'play') as plays,
  COUNT(*) FILTER (WHERE event = 'complete') as completes,
  COUNT(*) FILTER (WHERE event = 'save') as saves,
  COUNT(*) FILTER (WHERE event = 'share') as shares,
  COUNT(*) FILTER (WHERE event = 'quote') as quotes,
  COUNT(*) FILTER (WHERE event = 'follow_author') as follows
FROM feed_events
WHERE audio_id = $1;

-- name: GetRecentEventStats :many
SELECT
  audio_id,
  COUNT(*) FILTER (WHERE event = 'impression') as impressions,
  COUNT(*) FILTER (WHERE event = 'preview_finished') as previews_finished,
  COUNT(*) FILTER (WHERE event = 'play') as plays,
  COUNT(*) FILTER (WHERE event = 'complete') as completes,
  COUNT(*) FILTER (WHERE event = 'save') as saves
FROM feed_events
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY audio_id;

