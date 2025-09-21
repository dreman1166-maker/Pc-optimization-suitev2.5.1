<#
.SYNOPSIS
    Simple Distribution Builder for PC Optimization Suite

.DESCRIPTION
    Creates a portable distribution package for easy sharing

.PARAMETER OutputPath
    Directory where the package will be created

.EXAMPLE
    .\SimpleDistribution.ps1 -OutputPath "C:\Distribution"
#>

param(
    [string]$OutputPath = ""
)

# Configuration
$script:Version = "2.0.1"
$script:CoreFiles = @(
    "PCOptimizationLauncher.ps1",
    "AdvancedDriverUpdater.ps1",
    "SystemLogger.ps1",
    "PCOptimizationSuite.ps1",
    "DriverUpdaterManager.ps1",
    "DriverUpdaterConfig.ini"
)

function Write-DistLog {
    param([string]$Message, [string]$Level = "Info")
    $colors = @{"Info"="White";"Success"="Green";"Warning"="Yellow";"Error"="Red"}
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function New-PortablePackage {
    param([string]$BuildPath)
    
    Write-DistLog "Creating portable package..." -Level Info
    
    $portablePath = Join-Path $BuildPath "PC_Optimization_Suite_Portable"
    if (Test-Path $portablePath) {
        Remove-Item $portablePath -Recurse -Force
    }
    New-Item -Path $portablePath -ItemType Directory -Force | Out-Null
    
    # Copy core files
    foreach ($file in $script:CoreFiles) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath -Destination $portablePath -Force
            Write-DistLog "Copied: $file" -Level Info
        }
    }
    
    # Copy additional files
    $additionalFiles = @("README.md", "SETUP_GUIDE.md")
    foreach ($file in $additionalFiles) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath -Destination $portablePath -Force
            Write-DistLog "Copied: $file" -Level Info
        }
    }
    
    # Create directories
    $directories = @("Config", "Logs", "Backups", "Updates", "Temp")
    foreach ($dir in $directories) {
        $dirPath = Join-Path $portablePath $dir
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
    }
    
    # Create launcher batch file
    $launcherBatch = @'
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
'@
    
    $launcherBatch | Set-Content (Join-Path $portablePath "Launch_PC_Optimizer.bat") -Encoding ASCII
    
    # Create readme
    $readmeContent = @'
PC Optimization Suite v2.0.1 - Portable Edition
===============================================

Quick Start:
1. Double-click "Launch_PC_Optimizer.bat"
2. Follow the first-run setup
3. Enjoy automatic system optimization!

Features:
- Advanced driver updates
- System optimization (8 categories)
- Gaming mode optimization
- Automatic updates
- Comprehensive logging
- Recovery system

Requirements:
- Windows 10/11
- PowerShell 5.1+
- Administrator rights recommended

For detailed documentation, see README.md and SETUP_GUIDE.md

Generated: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
'@
    
    $readmeContent | Set-Content (Join-Path $portablePath "START_HERE.txt") -Encoding UTF8
    
    Write-DistLog "Portable package created successfully" -Level Success
    return $portablePath
}

# Main execution
try {
    Clear-Host
    Write-Host "PC Optimization Suite - Distribution Builder" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path $PSScriptRoot -Parent) "Distribution"
    }
    
    Write-DistLog "Output directory: $OutputPath" -Level Info
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Create portable package
    $packagePath = New-PortablePackage -BuildPath $OutputPath
    
    # Create ZIP archive
    $zipPath = "$packagePath.zip"
    if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
        Write-DistLog "Creating ZIP archive..." -Level Info
        Compress-Archive -Path "$packagePath\*" -DestinationPath $zipPath -Force
        Write-DistLog "ZIP created: $zipPath" -Level Success
    }
    
    Write-Host ""
    Write-Host "Distribution package created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Package location: $packagePath" -ForegroundColor Yellow
    if (Test-Path $zipPath) {
        Write-Host "ZIP archive: $zipPath" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "To share with others:" -ForegroundColor Cyan
    Write-Host "1. Share the ZIP file or entire folder" -ForegroundColor White
    Write-Host "2. Recipients run 'Launch_PC_Optimizer.bat'" -ForegroundColor White
    Write-Host "3. They get automatic updates when you publish new versions!" -ForegroundColor White
    Write-Host ""
    
    $openFolder = Read-Host "Open output folder? (Y/N) [Y]"
    if ($openFolder -eq '' -or $openFolder -match '^[Yy]') {
        Start-Process "explorer.exe" -ArgumentList $OutputPath
    }
}
catch {
    Write-DistLog "Error: $($_.Exception.Message)" -Level Error
    Read-Host "Press Enter to exit"
}