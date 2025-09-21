@echo off
REM ========================================
REM  PC Optimization Suite v2.6.1
REM  Bug Fix Release Publishing Script
REM ========================================

echo ========================================
echo  GitHub Publishing Script v2.6.1
echo  Bug Fix Release - Stable Version
echo ========================================
echo.
echo This script will publish the bug fix release v2.6.1 to GitHub.
echo This version fixes small bugs and improves stability.
echo.
pause

REM Check if git is available
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH!
    echo Please install Git and try again.
    pause
    exit /b 1
)

echo Current Git Status:
echo -------------------
git status

echo.
echo Creating release tag v2.6.1...
git tag -a v2.6.1 -m "PC Optimization Suite v2.6.1 - Bug Fix Release: Fixed syntax errors and improved stability"
if errorlevel 1 (
    echo ERROR: Failed to create tag!
    pause
    exit /b 1
)
echo ✅ Tag created successfully!

echo.
echo Pushing to GitHub...
git push origin main
if errorlevel 1 (
    echo ERROR: Failed to push repository!
    pause
    exit /b 1
)
git push origin --tags
if errorlevel 1 (
    echo ERROR: Failed to push tags!
    pause
    exit /b 1
)
echo ✅ Repository and tags pushed successfully!

echo.
echo Opening release notes...
start notepad RELEASE_NOTES_v2.6.1.md

echo.
echo ========================================
echo  Publishing Complete!
echo ========================================
echo.
echo Bug Fix Release v2.6.1 has been published to GitHub.
echo.
echo Key improvements in this release:
echo ✅ Fixed PowerShell syntax errors
echo ✅ Improved script stability and reliability
echo ✅ Enhanced error handling and performance
echo ✅ All major features working perfectly
echo.
echo Manual steps for GitHub release:
echo 1. Go to: https://github.com/yourusername/PC-Optimization-Suite/releases/new
echo 2. Select tag: v2.6.1
echo 3. Title: "PC Optimization Suite v2.6.1 - Bug Fix Release"
echo 4. Copy release notes from the opened file
echo 5. Attach files:
echo    - PCOptimizationGUI.ps1
echo    - README.md
echo    - LAUNCH_V2.6.1.bat
echo    - RELEASE_NOTES_v2.6.1.md
echo 6. Mark as "Latest release"
echo 7. Click "Publish release"
echo.
echo ✅ Ready for stable production use!
echo.
pause