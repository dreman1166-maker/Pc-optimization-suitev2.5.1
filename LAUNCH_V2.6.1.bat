@echo off
echo ========================================
echo  PC Optimization Suite v2.6.1 Launcher
echo  Bug Fix Release - Stable Version
echo ========================================
echo.
echo Starting PC Optimization Suite...
echo All bugs fixed - professional stability!
echo.

REM Change to script directory
cd /d "%~dp0"

REM Run the PowerShell script with enhanced error handling
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { . '.\PCOptimizationGUI.ps1'; Write-Host 'PC Optimization Suite v2.6.1 started successfully!' -ForegroundColor Green } catch { Write-Host 'Error: ' $_.Exception.Message -ForegroundColor Red; Write-Host 'If you see this message, please run as Administrator.' -ForegroundColor Yellow; Read-Host 'Press Enter to exit' } }"

echo.
echo Thank you for using PC Optimization Suite v2.6.1!
pause