# Fix qr_code_scanner build issues
# Run this script if you get namespace or JVM target errors after running flutter pub get

$buildGradlePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\qr_code_scanner-1.0.1\android\build.gradle"

if (Test-Path $buildGradlePath) {
    Write-Host "Fixing qr_code_scanner build configuration..." -ForegroundColor Yellow
    
    $content = Get-Content $buildGradlePath -Raw
    $needsUpdate = $false
    
    # Check if namespace exists
    if (-not ($content -match "namespace 'net.touchcapture.qr.flutterqr'")) {
        # Add namespace after compileSdkVersion
        $content = $content -replace "(compileSdkVersion \d+)", "`$1`n    namespace 'net.touchcapture.qr.flutterqr'"
        $needsUpdate = $true
        Write-Host "  - Namespace added" -ForegroundColor Green
    } else {
        Write-Host "  - Namespace already exists" -ForegroundColor Gray
    }
    
    # Check if kotlinOptions exists
    if (-not ($content -match "kotlinOptions")) {
        # Add kotlinOptions after compileOptions
        $content = $content -replace "(targetCompatibility JavaVersion\.VERSION_1_8\s*\n\s*\})", "`$1`n`n    kotlinOptions {`n        jvmTarget = '1.8'`n    }"
        $needsUpdate = $true
        Write-Host "  - Kotlin JVM target added" -ForegroundColor Green
    } else {
        Write-Host "  - Kotlin JVM target already configured" -ForegroundColor Gray
    }
    
    if ($needsUpdate) {
        Set-Content $buildGradlePath -Value $content -NoNewline
        Write-Host "`nFix applied successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nNo fixes needed. Configuration is already correct." -ForegroundColor Green
    }
} else {
    Write-Host "Error: qr_code_scanner package not found at expected location." -ForegroundColor Red
    Write-Host "Please run 'flutter pub get' first." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nYou can now try building your app again." -ForegroundColor Cyan

