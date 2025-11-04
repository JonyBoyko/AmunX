# PowerShell migration script for Windows
param(
    [string]$Direction = "up",
    [string]$DbHost = "localhost",
    [int]$DbPort = 5432,
    [string]$DbUser = "postgres",
    [string]$DbPassword = "postgres",
    [string]$DbName = "amunx",
    [string]$DbSslMode = "disable"
)

# Validate direction
if ($Direction -ne "up" -and $Direction -ne "down") {
    Write-Host "Error: Direction must be 'up' or 'down'" -ForegroundColor Red
    Write-Host "Usage: .\migrate.ps1 [-Direction up|down]"
    exit 1
}

# Construct DB URL
$DbUrl = "postgres://${DbUser}:${DbPassword}@${DbHost}:${DbPort}/${DbName}?sslmode=${DbSslMode}"

Write-Host "Running migrations $Direction..." -ForegroundColor Green
Write-Host "Database: $DbUrl" -ForegroundColor Yellow

# Check if Docker is available
try {
    docker --version | Out-Null
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Determine network
$Network = "amunx_default"

# Check if network exists
$NetworkExists = docker network inspect $Network 2>$null
if (-not $NetworkExists) {
    Write-Host "Warning: Network '$Network' not found. Trying without network..." -ForegroundColor Yellow
    $NetworkFlag = ""
} else {
    $NetworkFlag = "--network $Network"
}

# For Docker Compose, adjust host to 'postgres' instead of 'localhost'
if ($DbHost -eq "localhost" -and $NetworkFlag) {
    Write-Host "Adjusting DB_HOST from localhost to postgres for Docker network" -ForegroundColor Yellow
    $DbHost = "postgres"
    $DbUrl = "postgres://${DbUser}:${DbPassword}@${DbHost}:${DbPort}/${DbName}?sslmode=${DbSslMode}"
}

# Get absolute path for migrations
$MigrationsPath = Join-Path (Get-Location) "backend\db\migrations"

Write-Host "Running migrations via Docker..." -ForegroundColor Yellow
Write-Host "Migrations path: $MigrationsPath" -ForegroundColor Cyan

# Run Docker command
$dockerArgs = @(
    "run",
    "--rm"
)

if ($NetworkFlag) {
    $dockerArgs += $NetworkFlag.Split(" ")
}

$dockerArgs += @(
    "-v",
    "${MigrationsPath}:/migrations",
    "migrate/migrate:latest",
    "-path=/migrations",
    "-database",
    $DbUrl,
    $Direction
)

& docker $dockerArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Migrations completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Migration failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

