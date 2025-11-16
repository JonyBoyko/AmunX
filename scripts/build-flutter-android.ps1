# PowerShell script for building Flutter Android APK

param(
    [string]$Mode = "release",
    [switch]$Install = $false,
    [string]$DeviceId = ""
)

Write-Host "📱 Building Flutter Android app..." -ForegroundColor Cyan

# Check if Flutter is installed
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Yellow
    exit 1
}

# Navigate to mobile directory
Push-Location mobile

try {
    # Get dependencies
    Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Yellow
    flutter pub get

    # Generate code
    Write-Host "🔨 Generating code..." -ForegroundColor Yellow
    flutter pub run build_runner build --delete-conflicting-outputs

    # Build APK
    Write-Host "🔨 Building $Mode APK..." -ForegroundColor Yellow
    if ($Mode -eq "release") {
        flutter build apk --release
        $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    } else {
        flutter build apk --debug
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    }

    if (Test-Path $apkPath) {
        Write-Host "✅ APK built successfully: $apkPath" -ForegroundColor Green
        
        # Install on device/emulator if requested
        if ($Install) {
            Write-Host "📲 Installing APK on device..." -ForegroundColor Yellow
            
            # Get device list
            $devices = flutter devices --machine | ConvertFrom-Json
            if ($devices.Length -eq 0) {
                Write-Host "❌ No devices found. Please start an emulator or connect a device." -ForegroundColor Red
                exit 1
            }

            # Select device
            $device = $null
            if ($DeviceId) {
                $device = $devices | Where-Object { $_.id -eq $DeviceId }
            } else {
                $device = $devices | Where-Object { $_.category -eq "mobile" } | Select-Object -First 1
            }

            if (-not $device) {
                Write-Host "❌ Device not found" -ForegroundColor Red
                exit 1
            }

            Write-Host "📱 Installing on device: $($device.name) ($($device.id))" -ForegroundColor Yellow
            
            # Install using adb
            $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
            if (Test-Path $adbPath) {
                & $adbPath -s $device.id install -r $apkPath
                Write-Host "✅ APK installed successfully!" -ForegroundColor Green
            } else {
                Write-Host "⚠️  ADB not found. Please install Android SDK Platform Tools" -ForegroundColor Yellow
                Write-Host "APK location: $apkPath" -ForegroundColor Cyan
            }
        } else {
            Write-Host "📦 APK location: $apkPath" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ APK build failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}


