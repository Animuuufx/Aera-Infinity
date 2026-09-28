param(
    [string]$InstallPath = "$PSScriptRoot\AeraInfinityServer",
    [string]$PublicHost = "217.61.240.140"
)

$ErrorActionPreference = "Stop"
Write-Host "=== Aera Infinity / InfinityServer installer ===" -ForegroundColor Cyan
Write-Host "Upstream: drathaxie/InfinityServer main" -ForegroundColor DarkCyan
Write-Host "Administrator is not required for the normal install." -ForegroundColor DarkCyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required and must be available in this PowerShell session."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python 3.12+ is required and must be available in this PowerShell session."
}

$pyVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
$pyParts = $pyVersion.Trim().Split(".")
if ([int]$pyParts[0] -ne 3 -or [int]$pyParts[1] -lt 12) {
    throw "Python 3.12+ is required. Found Python $pyVersion."
}

if (-not (Test-Path "$InstallPath\.git")) {
    git clone --branch main --single-branch https://github.com/drathaxie/InfinityServer.git "$InstallPath"
    if ($LASTEXITCODE -ne 0) { throw "git clone failed." }
} else {
    Push-Location $InstallPath
    try {
        git restore server/server.py server/webapi.py 2>$null
        git fetch origin main
        git checkout main
        git pull --ff-only origin main
        if ($LASTEXITCODE -ne 0) { throw "git update failed." }
    }
    finally {
        Pop-Location
    }
}

$AeraDir = Join-Path $InstallPath "Aera"
New-Item -ItemType Directory -Force -Path $AeraDir | Out-Null
Copy-Item "$PSScriptRoot\aera_overlay.py" "$AeraDir\aera_overlay.py" -Force
Copy-Item "$PSScriptRoot\UPSTREAM.txt" "$AeraDir\UPSTREAM.txt" -Force
Copy-Item "$PSScriptRoot\START_AERA_INFINITYSERVER.bat" "$InstallPath\START_AERA_INFINITYSERVER.bat" -Force
Copy-Item "$PSScriptRoot\STOP_AERA_INFINITYSERVER.bat" "$InstallPath\STOP_AERA_INFINITYSERVER.bat" -Force
Copy-Item "$PSScriptRoot\UPDATE_AERA_INFINITYSERVER.bat" "$InstallPath\UPDATE_AERA_INFINITYSERVER.bat" -Force

python "$AeraDir\aera_overlay.py" "$InstallPath"
if ($LASTEXITCODE -ne 0) { throw "Aera overlay failed." }

$envFile = @"
@echo off
set INFINITY_DB=sqlite
set INFINITY_PUBLIC_HOST=$PublicHost
set INFINITY_GAME_HOST=0.0.0.0
set INFINITY_GAME_PORT=6677
set INFINITY_API_HOST=0.0.0.0
set INFINITY_API_PORT=6678
rem Replace before exposing staff editors publicly:
set INFINITY_EDIT_PASS=CHANGE_ME_BEFORE_PUBLIC_USE
"@
Set-Content -Path "$InstallPath\AERA_ENV.bat" -Value $envFile -Encoding ASCII

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if ($isAdmin) {
    netsh advfirewall firewall add rule name="Aera Infinity Game 6677" dir=in action=allow protocol=TCP localport=6677 | Out-Null
    netsh advfirewall firewall add rule name="Aera Infinity API 6678" dir=in action=allow protocol=TCP localport=6678 | Out-Null
    Write-Host "Firewall rules for TCP 6677/6678 were added." -ForegroundColor Green
} else {
    Write-Host "Firewall rules were not changed because PowerShell is not elevated." -ForegroundColor Yellow
    Write-Host "Only elevate later if you need to open TCP 6677/6678 in Windows Firewall." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installed to: $InstallPath" -ForegroundColor Green
Write-Host "Python: $pyVersion" -ForegroundColor Green
Write-Host "Run START_AERA_INFINITYSERVER.bat" -ForegroundColor Green
Write-Host "Aera client API: http://$PublicHost`:6678/" -ForegroundColor Green
