-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1 LIMIT 1;

-- name: GetUserByHandle :one
SELECT * FROM users WHERE handle = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
  email,
  handle,
  display_name,
  avatar,
  is_anon,
  plan,
  settings_json
) VALUES (
  $1, $2, $3, $4, $5, $6, $7
) RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET
  display_name = COALESCE(sqlc.narg('display_name'), display_name),
  avatar = COALESCE(sqlc.narg('avatar'), avatar),
  settings_json = COALESCE(sqlc.narg('settings_json'), settings_json),
  updated_at = now()
WHERE id = $1
RETURNING *;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = $1;

-- name: GetUserProfile :one
SELECT * FROM profiles WHERE user_id = $1 LIMIT 1;

-- name: UpsertUserProfile :one
INSERT INTO profiles (
  user_id,
  avatar_url,
  bio,
  settings
) VALUES (
  $1, $2, $3, $4
)
ON CONFLICT (user_id)
DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  bio = EXCLUDED.bio,
  settings = EXCLUDED.settings,
  updated_at = now()
RETURNING *;

-- name: FollowUser :exec
INSERT INTO user_follows (follower_id, followee_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: UnfollowUser :exec
DELETE FROM user_follows
WHERE follower_id = $1 AND followee_id = $2;

-- name: GetUserFollowers :many
SELECT u.*
FROM users u
JOIN user_follows f ON f.follower_id = u.id
WHERE f.followee_id = $1
ORDER BY f.created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetUserFollowing :many
SELECT u.*
FROM users u
JOIN user_follows f ON f.followee_id = u.id
WHERE f.follower_id = $1
ORDER BY f.created_at DESC
LIMIT $2 OFFSET $3;

-- name: IsFollowing :one
SELECT EXISTS(
  SELECT 1 FROM user_follows
  WHERE follower_id = $1 AND followee_id = $2
);

