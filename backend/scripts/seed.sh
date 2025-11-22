#!/usr/bin/env bash
set -euo pipefail

# Seed script runner for local development
# Usage: ./scripts/seed.sh [reset]

DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/amunx?sslmode=disable}"

if [ "${1:-}" = "reset" ]; then
  echo "⚠️  Resetting database (this will delete all data)..."
  docker exec amunx-postgres-1 psql -U postgres -d amunx -c "TRUNCATE TABLE audio_items, comments, likes, saves, user_follows, feed_events, summaries CASCADE;"
  docker exec amunx-postgres-1 psql -U postgres -d amunx -c "TRUNCATE TABLE users CASCADE;"
  echo "✅ Database reset complete"
fi

echo "🌱 Seeding database with test data..."
docker exec -i amunx-postgres-1 psql -U postgres -d amunx < db/seed.sql

echo "✅ Seed complete!"
echo ""
echo "Test users created:"
echo "  - test1@example.com (testuser1)"
echo "  - test2@example.com (testuser2)"
echo "  - test3@example.com (testuser3)"
echo "  - test4@example.com (testuser4)"
echo "  - test5@example.com (testuser5)"

