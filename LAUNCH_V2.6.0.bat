@echo off
echo ========================================
echo  PC Optimization Suite v2.6.0 Launcher
echo ========================================
echo.
echo Starting PC Optimization Suite...
echo This may take a moment to load all features.
echo.

REM Change to script directory
cd /d "%~dp0"

REM Run the PowerShell script with error handling
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { . '.\PCOptimizationGUI.ps1'; Write-Host 'Application started successfully!' -ForegroundColor Green } catch { Write-Host 'Error: ' $_.Exception.Message -ForegroundColor Red; Write-Host 'Press any key to exit...'; Read-Host } }"

echo.
echo Application closed.
pause