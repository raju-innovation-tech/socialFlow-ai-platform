# SocialFlow AI - Unified Test Suite Runner (PowerShell)
$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SocialFlow AI - Unified Quality & Test Suite" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Flutter Admin Tests
Write-Host "`n[1/3] Running Flutter Static Analysis..." -ForegroundColor Yellow
Set-Location "$RootDir\flutter_admin"
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter analysis failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/3] Running Flutter Widget & Unit Tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter tests failed!" -ForegroundColor Red
    exit 1
}

# 2. Backend Pytest Tests
Write-Host "`n[3/3] Running Backend Pytest Suites..." -ForegroundColor Yellow
Set-Location $RootDir
pytest backend/tests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend tests failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " ALL QUALITY CHECKS & TESTS PASSED SUCCESSFULLY! (100% Green)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

