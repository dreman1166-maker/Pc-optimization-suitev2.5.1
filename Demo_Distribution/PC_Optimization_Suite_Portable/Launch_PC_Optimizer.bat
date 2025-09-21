@echo off
title PC Optimization Suite v2.5.1 - Portable Launcher
color 0a
echo.
echo ================================================
echo  PC Optimization Suite v2.5.1 - Portable
echo ================================================
echo.
echo Starting PC Optimization Suite...
echo Please wait while the program loads...
echo.

REM Change to the directory where this batch file is located
cd /d "%~dp0"

REM Try to run the main GUI first
echo Launching main GUI interface...
powershell.exe -ExecutionPolicy Bypass -NoExit -Command "try { & '%~dp0PCOptimizationGUI.ps1' } catch { Write-Host 'GUI not found. Trying launcher...' -ForegroundColor Yellow; & '%~dp0PCOptimizationLauncher.ps1' }"

REM Fallback message
echo.
echo ================================================
echo Thank you for using PC Optimization Suite!
echo ================================================
echo.
echo Window will stay open until you close it manually.
echo Press Ctrl+C or close this window when done.
echo.

REM Keep the window open indefinitely
:keepopen
timeout /t 10 /nobreak >nul
goto keepopen
