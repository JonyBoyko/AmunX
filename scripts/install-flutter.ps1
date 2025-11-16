# PowerShell script to install Flutter on Windows

Write-Host "📱 Installing Flutter SDK..." -ForegroundColor Cyan

$flutterPath = "C:\src\flutter"
$flutterZip = "$env:TEMP\flutter_windows.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

# Check if Flutter already installed
if (Test-Path $flutterPath) {
    Write-Host "✅ Flutter already installed at $flutterPath" -ForegroundColor Green
    $env:Path += ";$flutterPath`\bin"
    flutter --version
    exit 0
}

# Create directory
Write-Host "📁 Creating directory: $flutterPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Path "C:\src" -Force | Out-Null

# Download Flutter
Write-Host "⬇️  Downloading Flutter SDK..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "✅ Download completed" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download Flutter: $_" -ForegroundColor Red
    Write-Host "Trying alternative method with git..." -ForegroundColor Yellow
    
    # Try git clone as fallback
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "📦 Cloning Flutter from GitHub..." -ForegroundColor Yellow
        git clone https://github.com/flutter/flutter.git -b stable $flutterPath
    } else {
        Write-Host "❌ Git not found. Please install Git or download Flutter manually:" -ForegroundColor Red
        Write-Host "   https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Cyan
        exit 1
    }
}

# Extract if downloaded as zip
if (Test-Path $flutterZip) {
    Write-Host "📦 Extracting Flutter..." -ForegroundColor Yellow
    Expand-Archive -Path $flutterZip -DestinationPath "C:\src" -Force
    Remove-Item $flutterZip -Force
    Write-Host "✅ Extraction completed" -ForegroundColor Green
}

# Add to PATH for current session
$env:Path += ";$flutterPath\bin"

# Add to user PATH permanently
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterPath\bin*") {
    Write-Host "🔧 Adding Flutter to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterPath`\bin", "User")
    Write-Host "✅ Added to PATH (restart terminal for permanent effect)" -ForegroundColor Green
}

# Verify installation
Write-Host "`n🔍 Verifying installation..." -ForegroundColor Yellow
& "$flutterPath`\bin`\flutter.bat" --version

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Flutter installed successfully!" -ForegroundColor Green
    Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart your terminal or run: `$env:Path += ';$flutterPath\bin'" -ForegroundColor White
    Write-Host "2. Run: flutter doctor" -ForegroundColor White
    Write-Host "3. Install Android Studio and Android SDK" -ForegroundColor White
    Write-Host "4. Run: flutter doctor --android-licenses" -ForegroundColor White
} else {
    Write-Host "`n❌ Flutter installation verification failed" -ForegroundColor Red
    exit 1
}
