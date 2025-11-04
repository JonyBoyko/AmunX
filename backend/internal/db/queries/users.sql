-- name: CreateUser :one
INSERT INTO users (handle, email, display_name, is_anon, plan)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, handle, email, display_name, avatar, is_anon, plan, settings_json, created_at, updated_at;

-- name: GetUserByEmail :one
SELECT id, handle, email, display_name, avatar, is_anon, plan, settings_json, created_at, updated_at
FROM users
WHERE email = $1;

-- name: GetUserByID :one
SELECT id, handle, email, display_name, avatar, is_anon, plan, settings_json, created_at, updated_at
FROM users
WHERE id = $1;
