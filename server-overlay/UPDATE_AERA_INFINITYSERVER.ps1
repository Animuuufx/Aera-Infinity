$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

if (-not (Test-Path ".git")) { throw "This updater must be run inside the installed InfinityServer checkout." }
if (-not (Test-Path ".\Aera\aera_overlay.py")) { throw "Aera overlay files are missing." }

Write-Host "Updating upstream InfinityServer main..." -ForegroundColor Cyan
& git restore server/server.py server/webapi.py server/handlers/world_cmds.py server/handlers/context.py
& git fetch origin main
& git checkout main
& git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw "Git update failed." }

& python ".\Aera\aera_overlay.py" $Root
if ($LASTEXITCODE -ne 0) { throw "Aera overlay failed against the new upstream revision." }

if (Test-Path ".\AERA_ENV.ps1") {
    . ".\AERA_ENV.ps1"
    if ($env:AERA_SYNC_ON_START -ne "0") {
        & python ".\server\aera_mysql_sync.py"
        if ($LASTEXITCODE -ne 0) { throw "Aera MySQL sync failed after update." }
    }
}
Write-Host "Aera Infinity updated from upstream main; local-data overlay reapplied." -ForegroundColor Green
