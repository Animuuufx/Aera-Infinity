param(
    [string]$InstallPath = "$PSScriptRoot\AeraInfinityServer",
    [string]$PublicHost = "217.61.240.140",
    [string]$MysqlHost = "127.0.0.1",
    [int]$MysqlPort = 3306,
    [string]$MysqlDatabase = "aera",
    [string]$MysqlUser = "root",
    [string]$MysqlPassword = "",
    [string]$GamefilesRoot = ""
)

$ErrorActionPreference = "Stop"
Write-Host "=== Aera Infinity Local-Data Installer v0.2.1 ===" -ForegroundColor Cyan
Write-Host "Upstream engine: drathaxie/InfinityServer latest main" -ForegroundColor DarkCyan
Write-Host "Aera content: YOUR MySQL + YOUR captured gamefiles only" -ForegroundColor DarkCyan
Write-Host "Administrator is not required for the normal install." -ForegroundColor DarkCyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required and must be available in this PowerShell session."
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python 3.12+ is required and must be available in this PowerShell session."
}
$pyVersion = (& python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')").Trim()
$parts = $pyVersion.Split('.')
if ([int]$parts[0] -ne 3 -or [int]$parts[1] -lt 12) {
    throw "Python 3.12+ is required. Found Python $pyVersion."
}

if (-not (Test-Path "$InstallPath\.git")) {
    Write-Host "Cloning InfinityServer main -> $InstallPath" -ForegroundColor Cyan
    & git clone --branch main --single-branch https://github.com/drathaxie/InfinityServer.git "$InstallPath"
    if ($LASTEXITCODE -ne 0) { throw "git clone failed." }
} else {
    Write-Host "Updating existing InfinityServer checkout..." -ForegroundColor Cyan
    Push-Location $InstallPath
    try {
        & git restore server/server.py server/webapi.py server/handlers/world_cmds.py server/handlers/context.py 2>$null
        & git fetch origin main
        & git checkout main
        & git pull --ff-only origin main
        if ($LASTEXITCODE -ne 0) { throw "git update failed." }
    } finally { Pop-Location }
}

Write-Host "Installing Aera Python bridge dependency..." -ForegroundColor Cyan
& python -m pip install --disable-pip-version-check --quiet "PyMySQL==1.1.1"
if ($LASTEXITCODE -ne 0) { throw "PyMySQL installation failed." }

$AeraDir = Join-Path $InstallPath "Aera"
New-Item -ItemType Directory -Force -Path $AeraDir | Out-Null
Copy-Item "$PSScriptRoot\aera_overlay.py" "$AeraDir\aera_overlay.py" -Force
Copy-Item "$PSScriptRoot\UPSTREAM.txt" "$AeraDir\UPSTREAM.txt" -Force
if (Test-Path "$PSScriptRoot\aera_mysql_sync.py") {
    Copy-Item "$PSScriptRoot\aera_mysql_sync.py" "$InstallPath\server\aera_mysql_sync.py" -Force
} elseif (Test-Path "$PSScriptRoot\aera_mysql_sync.py.gz.b64") {
    $encoded = (Get-Content "$PSScriptRoot\aera_mysql_sync.py.gz.b64" -Raw).Trim()
    $compressed = [Convert]::FromBase64String($encoded)
    $input = New-Object System.IO.MemoryStream(,$compressed)
    $gzip = New-Object System.IO.Compression.GZipStream($input,[System.IO.Compression.CompressionMode]::Decompress)
    $output = New-Object System.IO.MemoryStream
    $gzip.CopyTo($output)
    $gzip.Dispose(); $input.Dispose()
    [System.IO.File]::WriteAllBytes("$InstallPath\server\aera_mysql_sync.py", $output.ToArray())
    $output.Dispose()
} else {
    throw "Aera MySQL sync bridge is missing from the integration package."
}
Copy-Item "$PSScriptRoot\START_AERA_INFINITYSERVER.ps1" "$InstallPath\START_AERA_INFINITYSERVER.ps1" -Force
Copy-Item "$PSScriptRoot\START_AERA_INFINITYSERVER.bat" "$InstallPath\START_AERA_INFINITYSERVER.bat" -Force
Copy-Item "$PSScriptRoot\STOP_AERA_INFINITYSERVER.bat" "$InstallPath\STOP_AERA_INFINITYSERVER.bat" -Force
Copy-Item "$PSScriptRoot\SYNC_AERA_MYSQL.bat" "$InstallPath\SYNC_AERA_MYSQL.bat" -Force
Copy-Item "$PSScriptRoot\UPDATE_AERA_INFINITYSERVER.ps1" "$InstallPath\UPDATE_AERA_INFINITYSERVER.ps1" -Force
Copy-Item "$PSScriptRoot\UPDATE_AERA_INFINITYSERVER.bat" "$InstallPath\UPDATE_AERA_INFINITYSERVER.bat" -Force

& python "$AeraDir\aera_overlay.py" "$InstallPath"
if ($LASTEXITCODE -ne 0) { throw "Aera overlay failed." }

if ([string]::IsNullOrWhiteSpace($GamefilesRoot)) {
    $direct = Join-Path $InstallPath "gamefiles\assetbundles\windows"
    if (Test-Path $direct) { $GamefilesRoot = $direct }
}
if ([string]::IsNullOrWhiteSpace($GamefilesRoot)) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $candidates = @()
    if (Test-Path $desktop) {
        Get-ChildItem $desktop -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Join-Path $_.FullName "server\gamefiles\assetbundles\windows"
            if (Test-Path $p) { $candidates += $p }
        }
    }
    if ($candidates.Count -gt 0) {
        $GamefilesRoot = $candidates[0]
        Write-Host "Auto-detected gamefiles: $GamefilesRoot" -ForegroundColor Green
    }
}
if ([string]::IsNullOrWhiteSpace($GamefilesRoot)) {
    $GamefilesRoot = Join-Path $InstallPath "gamefiles\assetbundles\windows"
    New-Item -ItemType Directory -Force -Path $GamefilesRoot | Out-Null
    Write-Host "No old gamefiles folder was detected." -ForegroundColor Yellow
    Write-Host "Set AERA_GAMEFILES_ROOT in $InstallPath\AERA_ENV.ps1 to your existing ...\server\gamefiles\assetbundles\windows folder." -ForegroundColor Yellow
}

function SQ([string]$v) { return ($v -replace "'", "''") }
$envText = @"
# Generated locally by the Aera Infinity installer. Do not commit this file.
`$env:INFINITY_DB = 'sqlite'
`$env:INFINITY_PUBLIC_HOST = '$(SQ $PublicHost)'
`$env:INFINITY_GAME_HOST = '0.0.0.0'
`$env:INFINITY_GAME_PORT = '6677'
`$env:INFINITY_API_HOST = '0.0.0.0'
`$env:INFINITY_API_PORT = '6678'
`$env:AERA_LOCAL_DATA_ONLY = '1'
`$env:AERA_SYNC_ON_START = '1'
`$env:AERA_START_MAP = 'battleon'
`$env:AERA_MYSQL_HOST = '$(SQ $MysqlHost)'
`$env:AERA_MYSQL_PORT = '$(SQ ([string]$MysqlPort))'
`$env:AERA_MYSQL_DATABASE = '$(SQ $MysqlDatabase)'
`$env:AERA_MYSQL_USER = '$(SQ $MysqlUser)'
`$env:AERA_MYSQL_PASSWORD = '$(SQ $MysqlPassword)'
`$env:AERA_GAMEFILES_ROOT = '$(SQ $GamefilesRoot)'
"@
Set-Content -Path "$InstallPath\AERA_ENV.ps1" -Value $envText -Encoding UTF8

Write-Host "Syncing your Aera MySQL database..." -ForegroundColor Cyan
Push-Location $InstallPath
try {
    . ".\AERA_ENV.ps1"
    & python ".\server\aera_mysql_sync.py"
    if ($LASTEXITCODE -ne 0) { throw "sync failed" }
} catch {
    Write-Host "Aera MySQL sync did not complete: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Edit $InstallPath\AERA_ENV.ps1 with your MySQL credentials/database, then run SYNC_AERA_MYSQL.bat." -ForegroundColor Yellow
} finally { Pop-Location }

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    netsh advfirewall firewall add rule name="Aera Infinity Game 6677" dir=in action=allow protocol=TCP localport=6677 | Out-Null
    netsh advfirewall firewall add rule name="Aera Infinity API 6678" dir=in action=allow protocol=TCP localport=6678 | Out-Null
    Write-Host "Firewall rules for TCP 6677/6678 added." -ForegroundColor Green
} else {
    Write-Host "Firewall was not changed (normal non-admin install)." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Installed to: $InstallPath" -ForegroundColor Green
Write-Host "Python: $pyVersion" -ForegroundColor Green
Write-Host "Config: $InstallPath\AERA_ENV.ps1" -ForegroundColor Green
Write-Host "Start: $InstallPath\START_AERA_INFINITYSERVER.bat" -ForegroundColor Green
Write-Host "NO live AQW Infinity content fallback is enabled." -ForegroundColor Green
