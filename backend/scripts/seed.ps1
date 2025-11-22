# PowerShell script for seeding database on Windows
# Usage: .\scripts\seed.ps1 [reset]

param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"

if ($Reset) {
    Write-Host "⚠️  Resetting database (this will delete all data)..." -ForegroundColor Yellow
    docker exec amunx-postgres-1 psql -U postgres -d amunx -c "TRUNCATE TABLE audio_items, comments, likes, saves, user_follows, feed_events, summaries CASCADE;"
    docker exec amunx-postgres-1 psql -U postgres -d amunx -c "TRUNCATE TABLE users CASCADE;"
    Write-Host "✅ Database reset complete" -ForegroundColor Green
}

Write-Host "🌱 Seeding database with test data..." -ForegroundColor Cyan
Get-Content backend\db\seed.sql | docker exec -i amunx-postgres-1 psql -U postgres -d amunx

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Seed complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test users created:" -ForegroundColor Cyan
    Write-Host "  - test1@example.com (testuser1)"
    Write-Host "  - test2@example.com (testuser2)"
    Write-Host "  - test3@example.com (testuser3)"
    Write-Host "  - test4@example.com (testuser4)"
    Write-Host "  - test5@example.com (testuser5)"
} else {
    Write-Host "❌ Seed failed!" -ForegroundColor Red
    exit 1
}

