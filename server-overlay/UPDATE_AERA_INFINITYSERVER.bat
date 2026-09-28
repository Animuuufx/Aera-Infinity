@echo off
setlocal
cd /d "%~dp0"
if not exist .git (
  echo ERROR: this must be run inside the installed InfinityServer checkout.
  pause
  exit /b 1
)
if not exist Aera\aera_overlay.py (
  echo ERROR: Aera overlay files are missing.
  pause
  exit /b 1
)

git restore server/server.py server/webapi.py
if errorlevel 1 goto :fail
git fetch origin main
if errorlevel 1 goto :fail
git checkout main
if errorlevel 1 goto :fail
git pull --ff-only origin main
if errorlevel 1 goto :fail
python "%~dp0Aera\aera_overlay.py" "%~dp0"
if errorlevel 1 goto :fail

echo.
echo Aera Infinity updated from upstream main and overlay reapplied.
exit /b 0

:fail
echo.
echo Update failed.
pause
exit /b 1
