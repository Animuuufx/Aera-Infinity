$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$EnvFile = Join-Path $Root "AERA_ENV.ps1"
if (-not (Test-Path $EnvFile)) {
    throw "AERA_ENV.ps1 is missing. Re-run INSTALL_AERA_INFINITYSERVER.ps1 or create the local configuration file."
}
. $EnvFile

Write-Host "=== Aera Infinity ===" -ForegroundColor Cyan
Write-Host "Content source: Aera MySQL ($env:AERA_MYSQL_DATABASE@$env:AERA_MYSQL_HOST)" -ForegroundColor DarkCyan
Write-Host "Gamefiles: $env:AERA_GAMEFILES_ROOT" -ForegroundColor DarkCyan
Write-Host "Upstream content fallback: DISABLED" -ForegroundColor DarkCyan

if ($env:AERA_SYNC_ON_START -ne "0") {
    Write-Host "Syncing Aera MySQL -> local runtime DB..." -ForegroundColor Cyan
    & python ".\server\aera_mysql_sync.py"
    if ($LASTEXITCODE -ne 0) {
        throw "Aera MySQL sync failed. Server was not started."
    }
}

$api = Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Aera Infinity API && python server\webapi.py" -WorkingDirectory $Root -PassThru
Start-Sleep -Seconds 1
$game = Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Aera Infinity Game && python server\server.py" -WorkingDirectory $Root -PassThru

Write-Host ""
Write-Host "Aera Infinity started." -ForegroundColor Green
Write-Host "  API : http://$env:INFINITY_PUBLIC_HOST`:$env:INFINITY_API_PORT/" -ForegroundColor Green
Write-Host "  Game: $env:INFINITY_PUBLIC_HOST`:$env:INFINITY_GAME_PORT" -ForegroundColor Green
Write-Host "  API PID: $($api.Id)  Game PID: $($game.Id)" -ForegroundColor DarkGray
