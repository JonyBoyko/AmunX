# PowerShell script for running Flutter app on emulator

param(
    [string]$DeviceName = "",
    [switch]$Create = $false
)

Write-Host "📱 Flutter Emulator Manager" -ForegroundColor Cyan

# Check if Flutter is installed
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Android SDK is available
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
if (-not (Test-Path $sdkPath)) {
    Write-Host "❌ Android SDK not found at $sdkPath" -ForegroundColor Red
    Write-Host "Please install Android Studio and Android SDK" -ForegroundColor Yellow
    exit 1
}

$emulatorPath = "$sdkPath\emulator\emulator.exe"
$adbPath = "$sdkPath\platform-tools\adb.exe"

if (-not (Test-Path $emulatorPath)) {
    Write-Host "❌ Android Emulator not found" -ForegroundColor Red
    exit 1
}

# List available emulators
Write-Host "`n📱 Available emulators:" -ForegroundColor Yellow
$emulators = & $emulatorPath -list-avds
if ($emulators.Length -eq 0) {
    Write-Host "No emulators found." -ForegroundColor Red
    if ($Create) {
        Write-Host "Please create an emulator using Android Studio:" -ForegroundColor Yellow
        Write-Host "1. Open Android Studio" -ForegroundColor Cyan
        Write-Host "2. Tools > Device Manager" -ForegroundColor Cyan
        Write-Host "3. Create Virtual Device" -ForegroundColor Cyan
    }
    exit 1
}

for ($i = 0; $i -lt $emulators.Length; $i++) {
    Write-Host "$($i + 1). $($emulators[$i])" -ForegroundColor Cyan
}

# Select emulator
if ($DeviceName) {
    $selectedEmulator = $emulators | Where-Object { $_ -eq $DeviceName }
    if (-not $selectedEmulator) {
        Write-Host "❌ Emulator '$DeviceName' not found" -ForegroundColor Red
        exit 1
    }
} else {
    $selectedEmulator = $emulators[0]
    Write-Host "`n📱 Using emulator: $selectedEmulator" -ForegroundColor Yellow
}

# Check if emulator is already running
$runningDevices = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
if ($runningDevices) {
    Write-Host "✅ Emulator already running" -ForegroundColor Green
} else {
    # Start emulator
    Write-Host "🚀 Starting emulator: $selectedEmulator" -ForegroundColor Yellow
    Start-Process -FilePath $emulatorPath -ArgumentList "-avd", $selectedEmulator -WindowStyle Minimized
    
    # Wait for emulator to be ready
    Write-Host "⏳ Waiting for emulator to be ready..." -ForegroundColor Yellow
    $maxWait = 120
    $waited = 0
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 2
        $waited += 2
        $devices = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
        if ($devices) {
            Write-Host "✅ Emulator is ready!" -ForegroundColor Green
            break
        }
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    
    if ($waited -ge $maxWait) {
        Write-Host "`n❌ Emulator failed to start in time" -ForegroundColor Red
        exit 1
    }
}

# Navigate to mobile directory and run Flutter
Push-Location mobile

try {
    Write-Host "`n🚀 Running Flutter app..." -ForegroundColor Yellow
    flutter run
} finally {
    Pop-Location
}


