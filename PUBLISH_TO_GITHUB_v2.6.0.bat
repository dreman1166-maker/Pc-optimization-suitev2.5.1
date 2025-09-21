@echo off
REM ========================================
REM  PC Optimization Suite v2.6.0
REM  GitHub Publishing Script
REM ========================================

echo ========================================
echo  GitHub Publishing Script v2.6.0
echo ========================================
echo.
echo This script will help you publish the latest version to GitHub.
echo Make sure you have committed all your changes first!
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
echo Checking for uncommitted changes...
git diff-index --quiet HEAD --
if errorlevel 1 (
    echo.
    echo WARNING: You have uncommitted changes!
    echo Please commit your changes before publishing.
    echo.
    echo Would you like to see the changes? (y/n)
    set /p choice=
    if /i "%choice%"=="y" (
        git diff
    )
    echo.
    echo Commit your changes and run this script again.
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Publishing Options
echo ========================================
echo.
echo 1. Create new release tag v2.6.0
echo 2. Push to GitHub repository
echo 3. Create release notes
echo 4. All of the above
echo.
set /p option="Select option (1-4): "

if "%option%"=="1" goto create_tag
if "%option%"=="2" goto push_repo
if "%option%"=="3" goto release_notes
if "%option%"=="4" goto full_publish
echo Invalid option selected.
pause
exit /b 1

:create_tag
echo.
echo Creating release tag v2.6.0...
git tag -a v2.6.0 -m "PC Optimization Suite v2.6.0 - Major Feature Update with Analytics, AI Engine, Gaming Suite & User Profiles"
if errorlevel 1 (
    echo ERROR: Failed to create tag!
    pause
    exit /b 1
)
echo Tag created successfully!
goto end

:push_repo
echo.
echo Pushing to GitHub...
git push origin main
if errorlevel 1 (
    echo ERROR: Failed to push to repository!
    pause
    exit /b 1
)
git push origin --tags
if errorlevel 1 (
    echo ERROR: Failed to push tags!
    pause
    exit /b 1
)
echo Repository updated successfully!
goto end

:release_notes
echo.
echo Opening release notes file...
start notepad RELEASE_NOTES_v2.6.0.md
echo.
echo Copy the content and create a new release on GitHub:
echo https://github.com/yourusername/PC-Optimization-Suite/releases/new
echo.
echo Select tag v2.6.0 and paste the release notes.
goto end

:full_publish
echo.
echo ========================================
echo  Full Publishing Process
echo ========================================
echo.
echo Step 1: Creating release tag...
git tag -a v2.6.0 -m "PC Optimization Suite v2.6.0 - Major Feature Update"
if errorlevel 1 (
    echo ERROR: Failed to create tag!
    pause
    exit /b 1
)
echo ✅ Tag created successfully!

echo.
echo Step 2: Pushing to GitHub...
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
echo Step 3: Opening release notes...
start notepad RELEASE_NOTES_v2.6.0.md
echo.
echo ✅ Release notes opened in Notepad
echo.
echo ========================================
echo  Manual Steps Required:
echo ========================================
echo.
echo 1. Go to: https://github.com/yourusername/PC-Optimization-Suite/releases/new
echo 2. Select tag: v2.6.0
echo 3. Title: "PC Optimization Suite v2.6.0 - Major Feature Update"
echo 4. Copy and paste the release notes from the opened file
echo 5. Attach the following files:
echo    - PCOptimizationGUI.ps1
echo    - README.md
echo    - LAUNCH_V2.6.0.bat
echo    - RELEASE_NOTES_v2.6.0.md
echo 6. Mark as "Latest release"
echo 7. Click "Publish release"
echo.
goto end

:end
echo.
echo ========================================
echo  Publishing Complete!
echo ========================================
echo.
echo Version 2.6.0 has been prepared for GitHub release.
echo.
echo Key features in this release:
echo ✅ User Profile System (Beginner/Intermediate/Professional)
echo ✅ Advanced Analytics Dashboard
echo ✅ AI-Powered Optimization Engine
echo ✅ Gaming Performance Suite
echo ✅ System Tray Integration
echo ✅ Enhanced UI and Performance
echo.
echo Don't forget to update your repository description with the new features!
echo.
pause