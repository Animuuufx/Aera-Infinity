@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0UPDATE_AERA_INFINITYSERVER.ps1"
if errorlevel 1 pause
