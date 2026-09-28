@echo off
setlocal
cd /d "%~dp0"
if exist AERA_ENV.bat call AERA_ENV.bat
if "%INFINITY_PUBLIC_HOST%"=="" set INFINITY_PUBLIC_HOST=217.61.240.140
if "%INFINITY_GAME_PORT%"=="" set INFINITY_GAME_PORT=6677
if "%INFINITY_API_PORT%"=="" set INFINITY_API_PORT=6678

start "Aera Infinity API" cmd /k "cd /d ""%~dp0"" && call AERA_ENV.bat && python server\webapi.py"
timeout /t 1 /nobreak >nul
start "Aera Infinity Game" cmd /k "cd /d ""%~dp0"" && call AERA_ENV.bat && python server\server.py"

echo Aera Infinity starting:
echo   API  %INFINITY_PUBLIC_HOST%:%INFINITY_API_PORT%
echo   Game %INFINITY_PUBLIC_HOST%:%INFINITY_GAME_PORT%
endlocal
