#!/usr/bin/env bash
set -euo pipefail

if ! command -v migrate >/dev/null; then
  echo "golang-migrate is required: https://github.com/golang-migrate/migrate" >&2
  exit 1
fi

DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable}"

migrate -path db/migrations -database "${DATABASE_URL}" "$@"

