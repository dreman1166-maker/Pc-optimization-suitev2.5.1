@echo off
REM ====================================================
REM  PC Optimization Suite v2.5.1 - FOOLPROOF LAUNCHER
REM ====================================================
REM This launcher is designed to NEVER close unexpectedly

title PC Optimization Suite v2.5.1 - Click to Start!
color 0a
mode con: cols=80 lines=25

:start
cls
echo.
echo  ████████████████████████████████████████████████████████████████████████████
echo  █                                                                          █
echo  █    PC OPTIMIZATION SUITE v2.5.1 - LATEST VERSION                        █
echo  █                                                                          █
echo  █    This window will STAY OPEN so you can see what's happening!          █
echo  █                                                                          █
echo  ████████████████████████████████████████████████████████████████████████████
echo.
echo  What would you like to do?
echo.
echo  [1] Launch PC Optimization GUI (Recommended)
echo  [2] Launch Professional Version  
echo  [3] View Help and Troubleshooting
echo  [4] Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto launch_gui
if "%choice%"=="2" goto launch_pro
if "%choice%"=="3" goto show_help
if "%choice%"=="4" goto exit_program
echo Invalid choice! Please enter 1, 2, 3, or 4.
timeout /t 2 >nul
goto start

:launch_gui
cls
echo.
echo ================================================
echo  LAUNCHING PC OPTIMIZATION GUI...
echo ================================================
echo.
echo Please wait while the program starts...
echo The GUI window should appear shortly.
echo.
echo NOTE: This command window will stay open for your reference.
echo You can minimize it or leave it open - it won't interfere.
echo.

cd /d "%~dp0"
start "" powershell.exe -ExecutionPolicy Bypass -File "%~dp0PCOptimizationGUI.ps1"

echo.
echo ✓ GUI has been launched!
echo.
echo If the GUI didn't appear, try option 2 (Professional Version)
echo or option 3 (Help) for troubleshooting.
echo.
goto menu_return

:launch_pro
cls
echo.
echo ================================================
echo  LAUNCHING PROFESSIONAL VERSION...
echo ================================================
echo.
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PCOptimizationLauncher_Professional.ps1"
goto menu_return

:show_help
cls
echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                                HELP & TROUBLESHOOTING
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo COMMON PROBLEMS:
echo.
echo 1. "Cannot run scripts" error:
echo    - Right-click this .bat file and choose "Run as Administrator"
echo    - Try option 2 (Professional Version) instead
echo.
echo 2. Nothing happens when clicking option 1:
echo    - The GUI might be starting in the background
echo    - Check your taskbar for "PC Optimization Suite"
echo    - Try option 2 instead
echo.
echo 3. PowerShell errors:
echo    - Make sure you extracted all files from the ZIP
echo    - Try running as Administrator
echo.
echo 4. Window closes immediately:
echo    - This launcher is designed to stay open!
echo    - If it still closes, run as Administrator
echo.
echo FILES NEEDED:
echo - PCOptimizationGUI.ps1 (main program)
echo - PCOptimizationLauncher_Professional.ps1 (backup)
echo - All other .ps1 files in the same folder
echo.
goto menu_return

:menu_return
echo.
echo ================================================
echo.
echo [1] Return to Main Menu
echo [2] Launch GUI Again  
echo [3] Exit
echo.
set /p return_choice="What would you like to do? "

if "%return_choice%"=="1" goto start
if "%return_choice%"=="2" goto launch_gui
if "%return_choice%"=="3" goto exit_program
goto menu_return

:exit_program
cls
echo.
echo ================================================
echo  Thank you for using PC Optimization Suite!
echo ================================================
echo.
echo This window will close in 5 seconds...
echo (or press any key to close immediately)
echo.
timeout /t 5
exit