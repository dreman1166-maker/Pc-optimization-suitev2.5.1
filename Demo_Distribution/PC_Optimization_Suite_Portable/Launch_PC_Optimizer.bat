@echo off
title PC Optimization Suite (Portable)
echo.
echo ================================================
echo  PC Optimization Suite v2.0.1 - Portable
echo ================================================
echo.
echo Starting PC Optimization Suite...
echo.
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PCOptimizationLauncher.ps1"
echo.
echo Thank you for using PC Optimization Suite!
pause
