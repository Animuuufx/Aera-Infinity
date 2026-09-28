@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0AERA_ENV.ps1'; python '%~dp0server\aera_mysql_sync.py'"
if errorlevel 1 pause
