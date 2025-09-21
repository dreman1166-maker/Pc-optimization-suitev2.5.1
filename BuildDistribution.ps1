<#
.SYNOPSIS
    PC Optimization Suite - Installation & Distribution Builder

.DESCRIPTION
    This script creates a complete installation package for the PC Optimization Suite
    that can be shared with others. It includes automatic update capabilities,
    self-extraction, and proper installation procedures.

.PARAMETER BuildType
    Type of build to create: 'Installer', 'Portable', 'Update'

.PARAMETER OutputPath
    Directory where the installation package will be created

.PARAMETER IncludeSource
    Include source code in the distribution package

.PARAMETER CreateUpdateServer
    Create update server configuration files

.EXAMPLE
    .\BuildDistribution.ps1 -BuildType Installer
    .\BuildDistribution.ps1 -BuildType Portable -OutputPath "C:\Distributions"
    .\BuildDistribution.ps1 -BuildType Update -CreateUpdateServer

.AUTHOR
    PC Optimization Suite Distribution Builder v1.0
#>

param(
    [ValidateSet("Installer", "Portable", "Update")]
    [string]$BuildType = "Installer",
    
    [string]$OutputPath = "",
    
    [switch]$IncludeSource,
    
    [switch]$CreateUpdateServer
)

# Configuration
$script:Version = "2.0.1"
$script:ProductName = "PC Optimization Suite"
$script:CompanyName = "Advanced System Tools"
$script:Copyright = "© 2025 Advanced System Tools. All rights reserved."
$script:SourcePath = $PSScriptRoot

# Required files for distribution
$script:CoreFiles = @(
    "PCOptimizationLauncher.ps1",
    "AdvancedDriverUpdater.ps1",
    "SystemLogger.ps1",
    "PCOptimizationSuite.ps1",
    "DriverUpdaterManager.ps1",
    "DriverUpdaterConfig.ini"
)

$script:OptionalFiles = @(
    "README.md",
    "SYSTEM_STATUS.md"
)

$script:DocumentationFiles = @(
    "privacy.html",
    "terms.html"
)

#region Utility Functions

function Write-BuildLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "Info"    = "White"
        "Warning" = "Yellow" 
        "Error"   = "Red"
        "Success" = "Green"
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

function Test-RequiredFiles {
    <#
    .SYNOPSIS
    Verifies all required files exist before building
    #>
    $missingFiles = @()
    
    foreach ($file in $script:CoreFiles) {
        $filePath = Join-Path $script:SourcePath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-BuildLog "Missing required files:" -Level Error
        foreach ($file in $missingFiles) {
            Write-BuildLog "  • $file" -Level Error
        }
        return $false
    }
    
    Write-BuildLog "All required files found" -Level Success
    return $true
}

function New-BuildDirectory {
    param([string]$Path)
    
    if (Test-Path $Path) {
        Write-BuildLog "Cleaning existing build directory: $Path" -Level Info
        Remove-Item $Path -Recurse -Force
    }
    
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Write-BuildLog "Created build directory: $Path" -Level Success
    return $Path
}

function Copy-CoreFiles {
    param(
        [string]$DestinationPath,
        [bool]$IncludeOptional = $true
    )
    
    Write-BuildLog "Copying core files to build directory..." -Level Info
    
    # Copy core files
    foreach ($file in $script:CoreFiles) {
        $sourcePath = Join-Path $script:SourcePath $file
        $destPath = Join-Path $DestinationPath $file
        
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath $destPath -Force
            Write-BuildLog "Copied: $file" -Level Info
        }
    }
    
    # Copy optional files if requested
    if ($IncludeOptional) {
        foreach ($file in ($script:OptionalFiles + $script:DocumentationFiles)) {
            $sourcePath = Join-Path $script:SourcePath $file
            if (Test-Path $sourcePath) {
                $destPath = Join-Path $DestinationPath $file
                Copy-Item $sourcePath $destPath -Force
                Write-BuildLog "Copied optional: $file" -Level Info
            }
        }
        
        # Copy Logs directory structure
        $logsSource = Join-Path $script:SourcePath "Logs"
        if (Test-Path $logsSource) {
            $logsDest = Join-Path $DestinationPath "Logs"
            New-Item -Path $logsDest -ItemType Directory -Force | Out-Null
            # Copy only .log files, not the recovery reports
            Get-ChildItem $logsSource -Filter "*.log" | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $logsDest $_.Name) -Force
            }
            Write-BuildLog "Copied logs directory structure" -Level Info
        }
    }
}

#endregion

#region Installer Builder

function New-InstallerPackage {
    param([string]$BuildPath)
    
    Write-BuildLog "Creating installer package..." -Level Info
    
    $installerPath = Join-Path $BuildPath "Installer"
    New-Item -Path $installerPath -ItemType Directory -Force | Out-Null
    
    # Copy all files
    Copy-CoreFiles -DestinationPath $installerPath -IncludeOptional $true
    
    # Create installer script
    $installerScript = @"
<#
.SYNOPSIS
    PC Optimization Suite Installer v$($script:Version)

.DESCRIPTION
    This installer will set up the PC Optimization Suite on your system with
    automatic update capabilities and proper configuration.

.AUTHOR
    $($script:CompanyName)
#>

# Installer Configuration
`$script:ProductName = "$($script:ProductName)"
`$script:Version = "$($script:Version)"
`$script:Company = "$($script:CompanyName)"
`$script:RequiredFiles = @(
    $(($script:CoreFiles | ForEach-Object { "`"$_`"" }) -join ",`n    ")
)

function Write-InstallerLog {
    param([string]`$Message, [string]`$Level = "Info")
    `$colors = @{"Info"="White";"Warning"="Yellow";"Error"="Red";"Success"="Green"}
    Write-Host "[`$(Get-Date -Format 'HH:mm:ss')] [`$Level] `$Message" -ForegroundColor `$colors[`$Level]
}

function Test-AdminPrivileges {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-InstallationBanner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           🛠️  PC OPTIMIZATION SUITE INSTALLER 🛠️             ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║                    Version `$(`$script:Version.PadRight(10))                     ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║              Professional System Optimization               ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-InstallationPath {
    Write-Host "📁 Choose Installation Location:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Program Files (Recommended)" -ForegroundColor White
    Write-Host "   `$env:ProgramFiles\`$(`$script:ProductName)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. User Profile" -ForegroundColor White  
    Write-Host "   `$env:USERPROFILE\Documents\`$(`$script:ProductName)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Custom Path" -ForegroundColor White
    Write-Host ""
    
    do {
        `$choice = Read-Host "Select installation location (1-3) [1]"
        if (`$choice -eq '' -or `$choice -eq '1') {
            return "`$env:ProgramFiles\`$(`$script:ProductName)"
        }
        elseif (`$choice -eq '2') {
            return "`$env:USERPROFILE\Documents\`$(`$script:ProductName)"
        }
        elseif (`$choice -eq '3') {
            `$customPath = Read-Host "Enter custom installation path"
            if (`$customPath -and (Test-Path (Split-Path `$customPath -Parent))) {
                return `$customPath
            }
            else {
                Write-Host "❌ Invalid path. Please try again." -ForegroundColor Red
            }
        }
        else {
            Write-Host "❌ Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red
        }
    } while (`$true)
}

function Install-Application {
    param([string]`$InstallPath)
    
    try {
        Write-InstallerLog "Starting installation to: `$InstallPath" -Level Info
        
        # Create installation directory
        if (-not (Test-Path `$InstallPath)) {
            New-Item -Path `$InstallPath -ItemType Directory -Force | Out-Null
            Write-InstallerLog "Created installation directory" -Level Success
        }
        
        # Copy files
        `$sourceDir = `$PSScriptRoot
        foreach (`$file in `$script:RequiredFiles) {
            `$sourcePath = Join-Path `$sourceDir `$file
            `$destPath = Join-Path `$InstallPath `$file
            
            if (Test-Path `$sourcePath) {
                Copy-Item `$sourcePath `$destPath -Force
                Write-InstallerLog "Installed: `$file" -Level Info
            }
            else {
                Write-InstallerLog "Warning: `$file not found in installer" -Level Warning
            }
        }
        
        # Copy additional files
        `$additionalFiles = @("README.md", "privacy.html", "terms.html")
        foreach (`$file in `$additionalFiles) {
            `$sourcePath = Join-Path `$sourceDir `$file
            if (Test-Path `$sourcePath) {
                Copy-Item `$sourcePath (Join-Path `$InstallPath `$file) -Force
                Write-InstallerLog "Installed: `$file" -Level Info
            }
        }
        
        # Create directories
        `$directories = @("Config", "Logs", "Backups", "Updates", "Temp")
        foreach (`$dir in `$directories) {
            `$dirPath = Join-Path `$InstallPath `$dir
            New-Item -Path `$dirPath -ItemType Directory -Force | Out-Null
        }
        Write-InstallerLog "Created directory structure" -Level Success
        
        # Create desktop shortcut
        `$createShortcut = Read-Host "Create desktop shortcut? (Y/N) [Y]"
        if (`$createShortcut -eq '' -or `$createShortcut -match '^[Yy]') {
            `$desktopPath = [Environment]::GetFolderPath("Desktop")
            `$shortcutPath = Join-Path `$desktopPath "`$(`$script:ProductName).lnk"
            `$launcherPath = Join-Path `$InstallPath "PCOptimizationLauncher.ps1"
            
            `$shell = New-Object -ComObject WScript.Shell
            `$shortcut = `$shell.CreateShortcut(`$shortcutPath)
            `$shortcut.TargetPath = "powershell.exe"
            `$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"`$launcherPath`""
            `$shortcut.WorkingDirectory = `$InstallPath
            `$shortcut.IconLocation = "shell32.dll,21"
            `$shortcut.Description = "`$(`$script:ProductName) - System Performance Tool"
            `$shortcut.Save()
            
            Write-InstallerLog "Desktop shortcut created" -Level Success
        }
        
        # Create start menu entry
        `$createStartMenu = Read-Host "Add to Start Menu? (Y/N) [Y]"
        if (`$createStartMenu -eq '' -or `$createStartMenu -match '^[Yy]') {
            `$startMenuPath = "`$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
            `$startMenuShortcut = Join-Path `$startMenuPath "`$(`$script:ProductName).lnk"
            `$launcherPath = Join-Path `$InstallPath "PCOptimizationLauncher.ps1"
            
            `$shell = New-Object -ComObject WScript.Shell
            `$shortcut = `$shell.CreateShortcut(`$startMenuShortcut)
            `$shortcut.TargetPath = "powershell.exe"
            `$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"`$launcherPath`""
            `$shortcut.WorkingDirectory = `$InstallPath
            `$shortcut.IconLocation = "shell32.dll,21"
            `$shortcut.Description = "`$(`$script:ProductName) - System Performance Tool"
            `$shortcut.Save()
            
            Write-InstallerLog "Start Menu entry created" -Level Success
        }
        
        # Set execution policy for the installation directory
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-InstallerLog "Execution policy configured" -Level Success
        }
        catch {
            Write-InstallerLog "Could not set execution policy automatically" -Level Warning
        }
        
        return `$InstallPath
    }
    catch {
        Write-InstallerLog "Installation failed: `$(`$_.Exception.Message)" -Level Error
        return `$null
    }
}

function Show-CompletionMessage {
    param([string]`$InstallPath)
    
    Write-Host ""
    Write-Host "🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Details:" -ForegroundColor Yellow
    Write-Host "• Product: `$(`$script:ProductName)" -ForegroundColor White
    Write-Host "• Version: `$(`$script:Version)" -ForegroundColor White
    Write-Host "• Location: `$InstallPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Launch from desktop shortcut or Start Menu" -ForegroundColor White
    Write-Host "2. Follow the first-run setup wizard" -ForegroundColor White
    Write-Host "3. The program will automatically check for updates" -ForegroundColor White
    Write-Host ""
    Write-Host "Support:" -ForegroundColor Yellow
    Write-Host "• Documentation: Check README.md in installation folder" -ForegroundColor White
    Write-Host "• Logs: Available in the Logs subfolder" -ForegroundColor White
    Write-Host "• Configuration: Stored in Config subfolder" -ForegroundColor White
    Write-Host ""
    
    `$launchNow = Read-Host "Launch `$(`$script:ProductName) now? (Y/N) [Y]"
    if (`$launchNow -eq '' -or `$launchNow -match '^[Yy]') {
        `$launcherPath = Join-Path `$InstallPath "PCOptimizationLauncher.ps1"
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"`$launcherPath`""
    }
}

# Main Installation Process
try {
    Show-InstallationBanner
    
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Host "⚠️  Administrator privileges recommended for best experience." -ForegroundColor Yellow
        Write-Host ""
        `$continue = Read-Host "Continue with current privileges? (Y/N) [Y]"
        if (`$continue -match '^[Nn]') {
            Write-Host "Please restart as administrator for optimal installation." -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit
        }
    }
    
    # Get installation path
    `$installPath = Get-InstallationPath
    
    Write-Host ""
    Write-Host "🚀 Starting Installation..." -ForegroundColor Cyan
    Write-Host ""
    
    # Perform installation
    `$result = Install-Application -InstallPath `$installPath
    
    if (`$result) {
        Show-CompletionMessage -InstallPath `$result
    }
    else {
        Write-Host "❌ Installation failed. Please check the error messages above." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
catch {
    Write-InstallerLog "Critical installer error: `$(`$_.Exception.Message)" -Level Error
    Read-Host "Press Enter to exit"
    exit 1
}
"@
    
    $installerScript | Set-Content (Join-Path $installerPath "Install.ps1") -Encoding UTF8
    
    # Create batch file for easy execution
    $batchContent = @"
@echo off
title PC Optimization Suite Installer
echo.
echo ====================================
echo  PC Optimization Suite Installer
echo ====================================
echo.
echo Starting PowerShell installer...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
echo.
echo Installation process completed.
pause
"@
    $batchContent | Set-Content (Join-Path $installerPath "Install.bat") -Encoding ASCII
    
    # Create info file
    $infoContent = @"
PC Optimization Suite v$($script:Version)
$($script:Copyright)

Installation Package Contents:
==============================

Core Files:
$(($script:CoreFiles | ForEach-Object { "• $_" }) -join "`n")

Features:
• Automatic driver updates
• System optimization and cleaning
• Performance monitoring
• Registry optimization
• Cache cleanup
• Gaming mode optimization
• Automatic update system
• Comprehensive logging
• Backup and recovery

Installation Instructions:
1. Run Install.bat (recommended) or Install.ps1
2. Follow the on-screen instructions
3. Choose installation location
4. Complete the setup wizard

System Requirements:
• Windows 10/11 (64-bit recommended)
• PowerShell 5.1 or higher
• Administrator privileges (recommended)
• 50MB free disk space
• Internet connection (for updates)

For support: Check README.md after installation
Generated: $(Get-Date)
"@
    $infoContent | Set-Content (Join-Path $installerPath "INSTALLER_INFO.txt") -Encoding UTF8
    
    Write-BuildLog "Installer package created successfully" -Level Success
    return $installerPath
}

#endregion

#region Portable Package Builder

function New-PortablePackage {
    param([string]$BuildPath)
    
    Write-BuildLog "Creating portable package..." -Level Info
    
    $portablePath = Join-Path $BuildPath "Portable"
    New-Item -Path $portablePath -ItemType Directory -Force | Out-Null
    
    # Copy all files
    Copy-CoreFiles -DestinationPath $portablePath -IncludeOptional $true
    
    # Create portable launcher
    $portableLauncher = @"
<#
.SYNOPSIS
    PC Optimization Suite - Portable Launcher

.DESCRIPTION
    Portable version launcher that runs without installation.
    All settings and data are stored in the application folder.
#>

# Force portable mode
`$env:PCOPT_PORTABLE = "true"
`$script:IsPortable = `$true

# Set working directory to script location
Set-Location `$PSScriptRoot

# Launch the main launcher
& "`$PSScriptRoot\PCOptimizationLauncher.ps1"
"@
    $portableLauncher | Set-Content (Join-Path $portablePath "LaunchPortable.ps1") -Encoding UTF8
    
    # Create portable batch file
    $portableBatch = @"
@echo off
title PC Optimization Suite (Portable)
cd /d "%~dp0"
echo Starting PC Optimization Suite in Portable Mode...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0LaunchPortable.ps1"
"@
    $portableBatch | Set-Content (Join-Path $portablePath "LaunchPortable.bat") -Encoding ASCII
    
    # Create portable readme
    $portableReadme = @"
PC Optimization Suite v$($script:Version) - Portable Edition
============================================================

This is a portable version that runs without installation.
All settings and data are stored in this folder.

Quick Start:
1. Double-click LaunchPortable.bat
2. Follow the first-run setup
3. The application is ready to use

Features:
• No installation required
• All data stored locally
• Automatic updates available
• Full functionality included
• Can be run from USB drives

Files:
• LaunchPortable.bat - Easy launcher
• LaunchPortable.ps1 - PowerShell launcher
• PCOptimizationLauncher.ps1 - Main launcher
• Core optimization scripts included

System Requirements:
• Windows 10/11
• PowerShell 5.1+
• 50MB free space
• Admin rights recommended

Generated: $(Get-Date)
"@
    $portableReadme | Set-Content (Join-Path $portablePath "PORTABLE_README.txt") -Encoding UTF8
    
    Write-BuildLog "Portable package created successfully" -Level Success
    return $portablePath
}

#endregion

#region Update Package Builder

function New-UpdatePackage {
    param([string]$BuildPath)
    
    Write-BuildLog "Creating update package..." -Level Info
    
    $updatePath = Join-Path $BuildPath "Update"
    New-Item -Path $updatePath -ItemType Directory -Force | Out-Null
    
    # Copy core files only (no user data)
    Copy-CoreFiles -DestinationPath $updatePath -IncludeOptional $false
    
    # Create update manifest
    $updateManifest = @{
        Version             = $script:Version
        ReleaseDate         = Get-Date
        UpdateType          = "Minor"
        RequiredFiles       = $script:CoreFiles
        UpdateNotes         = @(
            "Enhanced system optimization algorithms",
            "Improved driver detection and updating",
            "Better error handling and logging",
            "Performance improvements",
            "Bug fixes and stability improvements"
        )
        Compatibility       = @{
            MinimumVersion     = "2.0.0"
            WindowsVersions    = @("Windows 10", "Windows 11")
            PowerShellVersions = @("5.1", "7.0+")
        }
        InstallInstructions = @{
            StopServices    = @()
            BackupFiles     = $script:CoreFiles
            ReplaceFiles    = $script:CoreFiles
            RestartRequired = $false
        }
    }
    
    $updateManifest | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $updatePath "update-manifest.json") -Encoding UTF8
    
    # Create update installer
    $updateInstaller = @"
<#
.SYNOPSIS
    PC Optimization Suite Update Installer

.DESCRIPTION
    Installs updates for the PC Optimization Suite
#>

param([string]`$InstallPath)

`$UpdateManifest = Get-Content "`$PSScriptRoot\update-manifest.json" -Raw | ConvertFrom-Json

function Install-Update {
    param([string]`$TargetPath)
    
    Write-Host "Installing PC Optimization Suite Update v`$(`$UpdateManifest.Version)..." -ForegroundColor Cyan
    
    # Create backup
    `$backupPath = Join-Path `$TargetPath "Backups\pre_update_`$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path `$backupPath -ItemType Directory -Force | Out-Null
    
    foreach (`$file in `$UpdateManifest.RequiredFiles) {
        `$sourcePath = Join-Path `$TargetPath `$file
        if (Test-Path `$sourcePath) {
            Copy-Item `$sourcePath `$backupPath -Force
        }
    }
    
    # Install new files
    foreach (`$file in `$UpdateManifest.RequiredFiles) {
        `$sourcePath = Join-Path `$PSScriptRoot `$file
        `$destPath = Join-Path `$TargetPath `$file
        
        if (Test-Path `$sourcePath) {
            Copy-Item `$sourcePath `$destPath -Force
            Write-Host "Updated: `$file" -ForegroundColor Green
        }
    }
    
    Write-Host "Update completed successfully!" -ForegroundColor Green
    Write-Host "Backup created at: `$backupPath" -ForegroundColor Yellow
}

if (`$InstallPath) {
    Install-Update -TargetPath `$InstallPath
}
else {
    Write-Host "Please specify the installation path:" -ForegroundColor Yellow
    `$path = Read-Host "Installation Path"
    if (`$path -and (Test-Path `$path)) {
        Install-Update -TargetPath `$path
    }
    else {
        Write-Host "Invalid path specified" -ForegroundColor Red
    }
}
"@
    $updateInstaller | Set-Content (Join-Path $updatePath "install-update.ps1") -Encoding UTF8
    
    Write-BuildLog "Update package created successfully" -Level Success
    return $updatePath
}

#endregion

#region Update Server Configuration

function New-UpdateServerConfig {
    param([string]$BuildPath)
    
    if (-not $CreateUpdateServer) {
        return
    }
    
    Write-BuildLog "Creating update server configuration..." -Level Info
    
    $serverPath = Join-Path $BuildPath "UpdateServer"
    New-Item -Path $serverPath -ItemType Directory -Force | Out-Null
    
    # Create version API endpoint simulation
    $versionApi = @{
        latest_version        = $script:Version
        release_date          = Get-Date
        download_url          = "https://your-server.com/downloads/PCOptimizationSuite_v$($script:Version).zip"
        update_notes          = @(
            "Enhanced performance optimization",
            "Improved driver detection",
            "Better system compatibility",
            "Bug fixes and stability improvements"
        )
        minimum_version       = "2.0.0"
        auto_update_available = $true
    }
    
    $versionApi | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $serverPath "version.json") -Encoding UTF8
    
    # Create simple update server script
    $serverScript = @"
<#
.SYNOPSIS
    Simple Update Server for PC Optimization Suite

.DESCRIPTION
    A basic HTTP server that provides update information and file downloads
    for the PC Optimization Suite automatic update system.
    
    This is intended for development/testing. For production use,
    implement proper web server with authentication and security.
#>

param(
    [int]`$Port = 8080,
    [string]`$UpdatePath = `$PSScriptRoot
)

Add-Type -AssemblyName System.Net.Http

function Start-UpdateServer {
    param([int]`$Port, [string]`$Path)
    
    `$listener = New-Object System.Net.HttpListener
    `$listener.Prefixes.Add("http://localhost:`$Port/")
    `$listener.Start()
    
    Write-Host "Update server started on http://localhost:`$Port" -ForegroundColor Green
    Write-Host "Serving files from: `$Path" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    
    try {
        while (`$listener.IsListening) {
            `$context = `$listener.GetContext()
            `$request = `$context.Request
            `$response = `$context.Response
            
            `$url = `$request.Url.LocalPath
            Write-Host "`$(Get-Date -Format 'HH:mm:ss') - `$(`$request.HttpMethod) `$url" -ForegroundColor Cyan
            
            if (`$url -eq "/api/version") {
                `$versionFile = Join-Path `$Path "version.json"
                if (Test-Path `$versionFile) {
                    `$content = Get-Content `$versionFile -Raw
                    `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$content)
                    `$response.ContentType = "application/json"
                    `$response.ContentLength64 = `$buffer.Length
                    `$response.OutputStream.Write(`$buffer, 0, `$buffer.Length)
                }
            }
            elseif (`$url.StartsWith("/download/")) {
                `$fileName = Split-Path `$url -Leaf
                `$filePath = Join-Path `$Path `$fileName
                
                if (Test-Path `$filePath) {
                    `$fileBytes = [System.IO.File]::ReadAllBytes(`$filePath)
                    `$response.ContentType = "application/octet-stream"
                    `$response.ContentLength64 = `$fileBytes.Length
                    `$response.OutputStream.Write(`$fileBytes, 0, `$fileBytes.Length)
                }
                else {
                    `$response.StatusCode = 404
                }
            }
            else {
                `$response.StatusCode = 404
            }
            
            `$response.Close()
        }
    }
    finally {
        `$listener.Stop()
    }
}

Start-UpdateServer -Port `$Port -Path `$UpdatePath
"@
    $serverScript | Set-Content (Join-Path $serverPath "UpdateServer.ps1") -Encoding UTF8
    
    # Create server documentation
    $serverDocs = @"
Update Server Setup Guide
========================

This folder contains files for setting up an update server for the
PC Optimization Suite automatic update system.

Files:
• UpdateServer.ps1 - Simple HTTP server for testing
• version.json - Version information API endpoint

Setup Instructions:

1. Development/Testing:
   - Run UpdateServer.ps1 to start a local test server
   - Update the UpdateServer configuration in clients to point to your server
   - Server runs on http://localhost:8080 by default

2. Production Deployment:
   - Upload version.json to your web server
   - Create API endpoint at: https://yourserver.com/api/version
   - Host update packages at: https://yourserver.com/downloads/
   - Update client configurations with your server URL

API Endpoints:
• GET /api/version - Returns version information
• GET /download/[filename] - Downloads update packages

Security Considerations:
• Implement HTTPS in production
• Add authentication if needed
• Validate file signatures
• Rate limiting
• Access logging

Client Configuration:
Update the UpdateServer setting in client configurations to point
to your server's API endpoint.

Example: https://yourserver.com/api
"@
    $serverDocs | Set-Content (Join-Path $serverPath "SERVER_SETUP.txt") -Encoding UTF8
    
    Write-BuildLog "Update server configuration created" -Level Success
}

#endregion

#region Main Execution

function Show-BuildBanner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      🏗️  PC OPTIMIZATION SUITE - DISTRIBUTION BUILDER 🏗️     ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║            Create distributable packages and installers     ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║                   Version $($script:Version.PadRight(10))                     ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-BuildConfiguration {
    if (-not $BuildType -or $BuildType -eq "") {
        Write-Host "📦 Select Build Type:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Installer Package (Full setup with wizard)" -ForegroundColor White
        Write-Host "2. Portable Package (No installation required)" -ForegroundColor White
        Write-Host "3. Update Package (For existing installations)" -ForegroundColor White
        Write-Host "4. All Packages" -ForegroundColor White
        Write-Host ""
        
        do {
            $choice = Read-Host "Select build type (1-4) [1]"
            switch ($choice) {
                "" { return "Installer" }
                "1" { return "Installer" }
                "2" { return "Portable" }
                "3" { return "Update" }
                "4" { return "All" }
                default { Write-Host "❌ Invalid choice. Please select 1-4." -ForegroundColor Red }
            }
        } while ($true)
    }
    
    return $BuildType
}

function Get-OutputDirectory {
    if ($OutputPath -and $OutputPath -ne "") {
        return $OutputPath
    }
    
    $defaultPath = Join-Path (Split-Path $script:SourcePath -Parent) "Distributions"
    Write-Host "📁 Output Directory:" -ForegroundColor Yellow
    Write-Host "Default: $defaultPath" -ForegroundColor Gray
    $customPath = Read-Host "Enter output path (Enter for default)"
    
    if ($customPath -and $customPath -ne "") {
        return $customPath
    }
    else {
        return $defaultPath
    }
}

# Main execution
try {
    Show-BuildBanner
    
    # Verify required files
    if (-not (Test-RequiredFiles)) {
        Write-BuildLog "Cannot continue without required files" -Level Error
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Get configuration
    $selectedBuildType = Get-BuildConfiguration
    $outputDir = Get-OutputDirectory
    
    Write-BuildLog "Build Configuration:" -Level Info
    Write-BuildLog "• Build Type: $selectedBuildType" -Level Info
    Write-BuildLog "• Output Directory: $outputDir" -Level Info
    Write-BuildLog "• Include Source: $IncludeSource" -Level Info
    Write-BuildLog "• Create Update Server: $CreateUpdateServer" -Level Info
    Write-Host ""
    
    # Create output directory
    $buildRoot = Join-Path $outputDir "PCOptimizationSuite_v$($script:Version)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $buildPath = New-BuildDirectory -Path $buildRoot
    
    # Build packages based on selection
    $packages = @()
    
    if ($selectedBuildType -eq "All" -or $selectedBuildType -eq "Installer") {
        $installerPath = New-InstallerPackage -BuildPath $buildPath
        $packages += @{ Type = "Installer"; Path = $installerPath }
    }
    
    if ($selectedBuildType -eq "All" -or $selectedBuildType -eq "Portable") {
        $portablePath = New-PortablePackage -BuildPath $buildPath
        $packages += @{ Type = "Portable"; Path = $portablePath }
    }
    
    if ($selectedBuildType -eq "All" -or $selectedBuildType -eq "Update") {
        $updatePath = New-UpdatePackage -BuildPath $buildPath
        $packages += @{ Type = "Update"; Path = $updatePath }
    }
    
    # Create update server configuration if requested
    New-UpdateServerConfig -BuildPath $buildPath
    
    # Create ZIP archives
    Write-BuildLog "Creating ZIP archives..." -Level Info
    foreach ($package in $packages) {
        $zipPath = "$($package.Path).zip"
        try {
            Compress-Archive -Path "$($package.Path)\*" -DestinationPath $zipPath -Force
            Write-BuildLog "Created: $($package.Type) package - $zipPath" -Level Success
        }
        catch {
            Write-BuildLog "Failed to create ZIP for $($package.Type): $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Create build summary
    $summary = @"
PC Optimization Suite v$($script:Version) - Build Summary
========================================================

Build Date: $(Get-Date)
Build Type: $selectedBuildType
Output Location: $buildRoot

Packages Created:
$(foreach ($pkg in $packages) { "• $($pkg.Type): $($pkg.Path)" })

Files Included:
$(foreach ($file in $script:CoreFiles) { "• $file" })

Distribution Instructions:
1. Test packages in clean environment
2. Verify all functionality works correctly  
3. Update server configurations if using auto-update
4. Distribute to end users

Notes:
- Installer package includes setup wizard
- Portable package requires no installation
- Update package is for existing installations
- All packages include automatic update capability

Support:
- Check README files in each package
- Verify system requirements are met
- Test on target Windows versions
"@
    
    $summary | Set-Content (Join-Path $buildPath "BUILD_SUMMARY.txt") -Encoding UTF8
    
    # Show completion message
    Write-Host ""
    Write-Host "🎉 BUILD COMPLETED SUCCESSFULLY! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "Build Summary:" -ForegroundColor Yellow
    Write-Host "• Output Location: $buildRoot" -ForegroundColor White
    Write-Host "• Packages Created: $($packages.Count)" -ForegroundColor White
    Write-Host "• Build Type: $selectedBuildType" -ForegroundColor White
    Write-Host ""
    
    $openFolder = Read-Host "Open output folder? (Y/N) [Y]"
    if ($openFolder -eq '' -or $openFolder -match '^[Yy]') {
        Start-Process "explorer.exe" -ArgumentList $buildRoot
    }
    
    Write-BuildLog "Build process completed successfully" -Level Success
}
catch {
    Write-BuildLog "Build process failed: $($_.Exception.Message)" -Level Error
    Write-Host ""
    Write-Host "❌ Build failed. Check the error message above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

#endregion