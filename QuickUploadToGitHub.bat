@echo off
echo ================================================
echo  PC Optimization Suite - Quick GitHub Upload
echo ================================================
echo.
echo This will upload your latest changes to GitHub
echo and create a new release automatically.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo 📦 Starting upload process...
echo.

powershell -ExecutionPolicy Bypass -File ".\PublishLatestVersion.ps1" -CreateRelease

echo.
echo ✅ Upload complete! Check your GitHub repository.
echo.
pause