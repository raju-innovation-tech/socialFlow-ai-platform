# SocialFlow AI - Developer Launch Script for Windows PowerShell
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "backend", "flutter", "docker")]
    [string]$Target = "backend"
)

$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SocialFlow AI - SaaS Development Launcher" -ForegroundColor Cyan
Write-Host " Target: $Target" -ForegroundColor Yellow
Write-Host " Root Directory: $RootDir" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Target -eq "backend" -or $Target -eq "all") {
    Write-Host "[1/2] Starting FastAPI Backend on http://localhost:8001..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$RootDir\backend'; python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload"
}

if ($Target -eq "flutter" -or $Target -eq "all") {
    Write-Host "[2/2] Starting Flutter Admin UI (Windows Desktop)..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$RootDir\flutter_admin'; flutter run -d windows"
}

if ($Target -eq "docker") {
    Write-Host "Starting Docker Compose Environment..." -ForegroundColor Green
    Set-Location $RootDir
    docker-compose up -d --build
    docker-compose ps
}

Write-Host "Launch triggered successfully!" -ForegroundColor Cyan

