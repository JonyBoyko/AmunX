#!/bin/bash
set -e

echo "🧪 Starting integration tests..."

# Start test services
echo "📦 Starting test Docker services..."
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Run migrations
echo "🔄 Running migrations..."
docker-compose -f docker-compose.test.yml exec -T postgres-test psql -U test -d amunx_test -c "SELECT 1" || true

# Run tests
echo "🧪 Running tests..."
docker-compose -f docker-compose.test.yml run --rm api-test go test -v ./internal/http/... -tags=integration

echo "📱 Running Flutter integration tests..."
pushd mobile >/dev/null
flutter test integration_test
popd >/dev/null

# Cleanup
echo "🧹 Cleaning up..."
docker-compose -f docker-compose.test.yml down -v

echo "✅ Tests completed!"


