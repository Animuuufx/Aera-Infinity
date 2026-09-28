@echo off
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":6677" ^| findstr "LISTENING"') do taskkill /PID %%P /F >nul 2>&1
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":6678" ^| findstr "LISTENING"') do taskkill /PID %%P /F >nul 2>&1
echo Aera Infinity processes on ports 6677/6678 stopped.
