@echo off
title GitHub Publisher for PC Optimization Suite
echo.
echo ================================================
echo  GitHub Publisher for PC Optimization Suite
echo ================================================
echo.
echo This will help you publish your software to GitHub
echo so others can download it and get automatic updates!
echo.

REM Check if Git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed!
    echo.
    echo Please install Git first from: https://git-scm.com/downloads
    echo Then run this script again.
    pause
    exit /b 1
)

echo [SUCCESS] Git is installed!
echo.

REM Initialize git repository if needed
if not exist ".git" (
    echo [INFO] Initializing Git repository...
    git init
    echo # PC Optimization Suite > .gitignore
    echo Logs/*.log >> .gitignore
    echo Logs/*.json >> .gitignore
    echo *.log >> .gitignore
    echo Temp/ >> .gitignore
    echo *Distribution*/ >> .gitignore
    echo *.zip >> .gitignore
    echo *token* >> .gitignore
    echo github-config.json >> .gitignore
    
    git add .gitignore
    git commit -m "Initial commit with gitignore"
    echo [SUCCESS] Git repository initialized!
) else (
    echo [INFO] Git repository already exists
)

echo.
echo [INFO] Adding project files to Git...
git add PCOptimizationLauncher.ps1
git add AdvancedDriverUpdater.ps1
git add SystemLogger.ps1
git add PCOptimizationSuite.ps1
git add DriverUpdaterManager.ps1
git add DriverUpdaterConfig.ini
git add README.md
git add SETUP_GUIDE.md
git add SimpleDistribution.ps1

git commit -m "PC Optimization Suite v2.0.1 - Professional system optimization software with automatic updates"

echo [SUCCESS] Files added to Git!
echo.

echo ================================================
echo  GitHub Repository Setup Instructions
echo ================================================
echo.
echo 1. Go to GitHub.com and sign in (create account if needed)
echo 2. Click the "+" icon in top right corner
echo 3. Select "New repository"
echo 4. Name: pc-optimization-suite (or your preferred name)
echo 5. Description: Professional PC optimization software with automatic updates
echo 6. Keep it PUBLIC (so others can download)
echo 7. DO NOT check "Add a README file" (we already have one)
echo 8. Click "Create repository"
echo.

echo After creating the repository on GitHub:
echo.
set /p REPO_URL="Enter your repository URL (e.g., https://github.com/username/pc-optimization-suite.git): "

if "%REPO_URL%"=="" (
    echo [ERROR] No repository URL provided
    pause
    exit /b 1
)

echo.
echo [INFO] Adding GitHub remote...
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%

echo [INFO] Pushing to GitHub...
git branch -M main
git push -u origin main

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to push to GitHub!
    echo.
    echo This might be because you need to authenticate.
    echo Try one of these solutions:
    echo.
    echo Option 1 - GitHub CLI (Recommended):
    echo   1. Install GitHub CLI from: https://cli.github.com/
    echo   2. Run: gh auth login
    echo   3. Run this script again
    echo.
    echo Option 2 - Personal Access Token:
    echo   1. Go to GitHub Settings ^> Developer settings ^> Personal access tokens
    echo   2. Generate new token with 'repo' permissions
    echo   3. Use token as password when Git prompts
    echo.
    echo Option 3 - GitHub Desktop:
    echo   1. Install GitHub Desktop
    echo   2. Sign in and clone your repository
    echo   3. Copy files to the cloned folder and commit/push
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================
echo  SUCCESS! Your software is now on GitHub!
echo ================================================
echo.
echo Repository URL: %REPO_URL%
echo.
echo Next steps:
echo 1. Go to your repository on GitHub
echo 2. Click "Releases" tab
echo 3. Click "Create a new release"
echo 4. Tag version: v2.0.1
echo 5. Release title: PC Optimization Suite v2.0.1
echo 6. Upload your distribution ZIP file from Demo_Distribution folder
echo.
echo To share with others:
echo 1. Send them your GitHub repository URL
echo 2. They click "Releases" and download the ZIP
echo 3. They extract and run Launch_PC_Optimizer.bat
echo 4. They get automatic updates when you publish new versions!
echo.

echo Creating distribution package for release...
powershell.exe -ExecutionPolicy Bypass -File "SimpleDistribution.ps1"

echo.
echo Your distribution package is ready in the Demo_Distribution folder!
echo Upload the PC_Optimization_Suite_Portable.zip file to your GitHub release.
echo.
pause