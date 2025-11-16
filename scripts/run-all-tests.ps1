# PowerShell script to run all tests

Write-Host "🧪 Running All Tests" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# 1. Unit tests
Write-Host "`n1️⃣ Running unit tests..." -ForegroundColor Yellow
Push-Location backend
try {
    go test ./... -v -short
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Unit tests failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Unit tests passed" -ForegroundColor Green
} finally {
    Pop-Location
}

# 2. Integration tests
Write-Host "`n2️⃣ Running integration tests..." -ForegroundColor Yellow
.\scripts\test.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Integration tests failed" -ForegroundColor Red
    exit 1
}

# 3. System tests (if API is running)
Write-Host "`n3️⃣ Running system tests..." -ForegroundColor Yellow
$apiRunning = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/healthz" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        $apiRunning = $true
    }
} catch {
    # API not running, skip system tests
}

if ($apiRunning) {
    Push-Location backend
    try {
        $env:API_BASE_URL = "http://localhost:8080"
        go test ./tests/system/... -v
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ System tests failed" -ForegroundColor Red
            exit 1
        }
        Write-Host "✅ System tests passed" -ForegroundColor Green
    } finally {
        Pop-Location
    }
} else {
    Write-Host "⚠️  API not running, skipping system tests" -ForegroundColor Yellow
    Write-Host "   Start API with: docker-compose up -d" -ForegroundColor Cyan
}

Write-Host "`n✅ All tests completed!" -ForegroundColor Green


