@echo off
title PC Optimization Suite v2.5.1 - Easy Launcher
color 0a
echo.
echo ================================================
echo  PC Optimization Suite v2.5.1 - LATEST VERSION
echo ================================================
echo.
echo Starting PC Optimization Suite GUI...
echo Please wait while the program loads...
echo.

REM Change to the directory where this batch file is located
cd /d "%~dp0"

REM Try to run the main GUI
echo Launching PCOptimizationGUI.ps1...
powershell.exe -ExecutionPolicy Bypass -NoExit -Command "try { & '%~dp0PCOptimizationGUI.ps1' } catch { Write-Host 'Error launching GUI. Press any key to try alternative launcher...' -ForegroundColor Red; Read-Host }"

REM If that fails, try the professional launcher
if errorlevel 1 (
    echo.
    echo Main GUI failed to start. Trying Professional Launcher...
    powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0PCOptimizationLauncher_Professional.ps1"
)

REM Keep window open no matter what
echo.
echo ================================================
echo Program finished or closed.
echo ================================================
echo.
echo Press any key to close this window...
pause >nul