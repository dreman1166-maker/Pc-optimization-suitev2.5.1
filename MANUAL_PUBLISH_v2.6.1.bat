@echo off
REM ========================================
REM  PC Optimization Suite v2.6.1
REM  GitHub Publishing Script (Manual)
REM ========================================

echo ========================================
echo  GitHub Publishing Script v2.6.1
echo  Bug Fix Release - Stable Version
echo ========================================
echo.
echo This script will help you publish v2.6.1 to GitHub manually.
echo.

REM Set Git path
set GIT_PATH="C:\Program Files\Git\bin\git.exe"

echo Checking Git installation...
%GIT_PATH% --version
if errorlevel 1 (
    echo ERROR: Git not found!
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Publishing Steps for v2.6.1
echo ========================================
echo.
echo 1. Go to your GitHub repository
echo 2. Click "Releases" 
echo 3. Click "Create a new release"
echo 4. Use these details:
echo.
echo    Tag version: v2.6.1
echo    Release title: PC Optimization Suite v2.6.1 - Bug Fix Release
echo.
echo 5. Copy this description:
echo.
echo "# PC Optimization Suite v2.6.1 - Bug Fix Release"
echo.
echo "This release fixes small bugs and improves stability:"
echo "- Fixed PowerShell syntax errors"
echo "- Improved script stability and error handling"
echo "- Enhanced compatibility across Windows versions"
echo "- Performance optimizations and faster startup"
echo.
echo "All major features from v2.6.0 remain fully functional:"
echo "- User Profile System (Beginner/Intermediate/Professional)"
echo "- Advanced Analytics Dashboard with real-time monitoring"
echo "- AI-Powered Optimization Engine with smart recommendations"
echo "- Gaming Performance Suite with FPS monitoring"
echo "- System Tray Integration with background operation"
echo.
echo "## Files to download:"
echo "- PCOptimizationGUI.ps1 (Main application)"
echo "- README.md (Documentation)"
echo "- LAUNCH_V2.6.1.bat (Launcher)"
echo "- RELEASE_NOTES_v2.6.1.md (Changelog)"
echo.
echo 6. Mark as "Latest release"
echo 7. Click "Publish release"
echo.
echo ========================================
echo  Current Project Status
echo ========================================
echo.
echo Files ready for upload:
if exist "PCOptimizationGUI.ps1" (echo ✅ PCOptimizationGUI.ps1) else (echo ❌ PCOptimizationGUI.ps1)
if exist "README.md" (echo ✅ README.md) else (echo ❌ README.md)
if exist "LAUNCH_V2.6.1.bat" (echo ✅ LAUNCH_V2.6.1.bat) else (echo ❌ LAUNCH_V2.6.1.bat)
if exist "RELEASE_NOTES_v2.6.1.md" (echo ✅ RELEASE_NOTES_v2.6.1.md) else (echo ❌ RELEASE_NOTES_v2.6.1.md)
echo.
echo Your PC Optimization Suite v2.6.1 is ready for GitHub!
echo.
pause