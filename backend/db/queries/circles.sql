-- name: CreateCircle :one
INSERT INTO circles (
  owner_id,
  name,
  description,
  is_local,
  city,
  country
) VALUES (
  $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetCircleByID :one
SELECT * FROM circles WHERE id = $1 LIMIT 1;

-- name: UpdateCircle :one
UPDATE circles
SET
  name = COALESCE(sqlc.narg('name'), name),
  description = COALESCE(sqlc.narg('description'), description),
  is_local = COALESCE(sqlc.narg('is_local'), is_local),
  city = COALESCE(sqlc.narg('city'), city),
  country = COALESCE(sqlc.narg('country'), country),
  updated_at = now()
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: DeleteCircle :exec
DELETE FROM circles WHERE id = $1;

-- name: ListCircles :many
SELECT * FROM circles
WHERE (sqlc.narg('city')::text IS NULL OR city = sqlc.narg('city'))
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListUserCircles :many
SELECT c.*
FROM circles c
JOIN circle_members cm ON cm.circle_id = c.id
WHERE cm.user_id = $1
ORDER BY cm.created_at DESC
LIMIT $2 OFFSET $3;

-- name: AddCircleMember :exec
INSERT INTO circle_members (circle_id, user_id, role)
VALUES ($1, $2, $3)
ON CONFLICT DO NOTHING;

-- name: UpdateCircleMemberRole :exec
UPDATE circle_members
SET role = $3
WHERE circle_id = $1 AND user_id = $2;

-- name: RemoveCircleMember :exec
DELETE FROM circle_members
WHERE circle_id = $1 AND user_id = $2;

-- name: GetCircleMembers :many
SELECT u.*, cm.role, cm.created_at as joined_at
FROM users u
JOIN circle_members cm ON cm.user_id = u.id
WHERE cm.circle_id = $1
ORDER BY cm.created_at ASC
LIMIT $2 OFFSET $3;

-- name: GetCircleMember :one
SELECT * FROM circle_members
WHERE circle_id = $1 AND user_id = $2
LIMIT 1;

-- name: IsCircleMember :one
SELECT EXISTS(
  SELECT 1 FROM circle_members
  WHERE circle_id = $1 AND user_id = $2
);

-- name: IsCircleModerator :one
SELECT EXISTS(
  SELECT 1 FROM circle_members
  WHERE circle_id = $1 AND user_id = $2 AND role IN ('owner', 'moderator')
);

