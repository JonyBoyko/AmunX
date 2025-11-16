# PowerShell script for running integration tests

Write-Host "🧪 Starting integration tests..." -ForegroundColor Cyan

# Start test services
Write-Host "📦 Starting test Docker services..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Run migrations (if needed)
Write-Host "🔄 Checking database..." -ForegroundColor Yellow

# Run tests
Write-Host "🧪 Running tests..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml run --rm api-test go test -v ./internal/http/... -tags=integration

# Cleanup
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down -v

Write-Host "✅ Tests completed!" -ForegroundColor Green


