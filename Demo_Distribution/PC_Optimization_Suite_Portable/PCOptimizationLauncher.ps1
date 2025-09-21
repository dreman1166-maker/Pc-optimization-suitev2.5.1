<#
.SYNOPSIS
    PC Optimization Suite - Auto-Update Manager and Distribution System

.DESCRIPTION
    This is the main launcher that handles automatic updates, dependency management,
    and provides a complete distributable package for the PC Optimization Suite.
    
    Features:
    - Automatic update checking and installation
    - Dependency management
    - Self-contained distribution
    - Version control and rollback
    - Multi-user deployment support

.PARAMETER CheckUpdates
    Check for updates without running the main program

.PARAMETER ForceUpdate
    Force download and install latest version

.PARAMETER UpdateServer
    Specify custom update server URL

.PARAMETER Version
    Show current version information

.PARAMETER InstallMode
    Run in installation mode for new deployments

.AUTHOR
    PC Optimization Suite v2.0 - Distribution Package

.EXAMPLE
    .\PCOptimizationLauncher.ps1
    .\PCOptimizationLauncher.ps1 -CheckUpdates
    .\PCOptimizationLauncher.ps1 -ForceUpdate
#>

param(
    [switch]$CheckUpdates,
    [switch]$ForceUpdate,
    [string]$UpdateServer = "https://your-update-server.com/api",
    [switch]$Version,
    [switch]$InstallMode
)

# Version and update configuration
$script:CurrentVersion = "2.0.1"
$script:ProgramName = "PC Optimization Suite"
$script:UpdateCheckInterval = 24 # hours
$script:RequiredFiles = @(
    "AdvancedDriverUpdater.ps1",
    "SystemLogger.ps1", 
    "PCOptimizationSuite.ps1",
    "DriverUpdaterManager.ps1"
)

# Paths and directories
$script:InstallPath = $PSScriptRoot
$script:ConfigPath = Join-Path $script:InstallPath "Config"
$script:UpdatePath = Join-Path $script:InstallPath "Updates"
$script:BackupPath = Join-Path $script:InstallPath "Backups"
$script:LogPath = Join-Path $script:InstallPath "Logs"
$script:TempPath = Join-Path $script:InstallPath "Temp"

# Configuration files
$script:VersionFile = Join-Path $script:ConfigPath "version.json"
$script:UpdateConfigFile = Join-Path $script:ConfigPath "update-config.json"
$script:UserConfigFile = Join-Path $script:ConfigPath "user-settings.json"

#region Initialization Functions

function Initialize-DirectoryStructure {
    <#
    .SYNOPSIS
    Creates necessary directory structure for the program
    #>
    $directories = @(
        $script:ConfigPath,
        $script:UpdatePath,
        $script:BackupPath,
        $script:LogPath,
        $script:TempPath
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created directory: $dir" -Level Info
        }
    }
}

function Initialize-Configuration {
    <#
    .SYNOPSIS
    Initializes configuration files with default settings
    #>
    
    # Version configuration
    $versionConfig = @{
        CurrentVersion = $script:CurrentVersion
        LastUpdateCheck = Get-Date
        UpdateChannel = "stable"
        InstallDate = Get-Date
        UpdateHistory = @()
    }
    
    # Update configuration
    $updateConfig = @{
        UpdateServer = $UpdateServer
        AutoUpdate = $true
        CheckInterval = $script:UpdateCheckInterval
        BackupCount = 5
        UpdateChannel = "stable"
        Enabled = $true
    }
    
    # User configuration
    $userConfig = @{
        FirstRun = $true
        AutoStartOptimization = $false
        NotificationLevel = "Normal"
        Theme = "Default"
        LanguageCode = "en-US"
        TelemetryEnabled = $false
    }
    
    # Save configurations
    $versionConfig | ConvertTo-Json -Depth 3 | Set-Content $script:VersionFile -Encoding UTF8
    $updateConfig | ConvertTo-Json -Depth 3 | Set-Content $script:UpdateConfigFile -Encoding UTF8
    $userConfig | ConvertTo-Json -Depth 3 | Set-Content $script:UserConfigFile -Encoding UTF8
    
    Write-LogMessage "Configuration files initialized" -Level Success
}

function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor White }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
        "Debug" { Write-Host $logEntry -ForegroundColor Gray }
    }
    
    # Log to file
    $logFile = Join-Path $script:LogPath "launcher_$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

#endregion

#region Update System Functions

function Test-InternetConnection {
    <#
    .SYNOPSIS
    Tests internet connectivity for update checking
    #>
    try {
        $testHosts = @("8.8.8.8", "1.1.1.1", "google.com")
        foreach ($testHost in $testHosts) {
            if (Test-NetConnection $host -InformationLevel Quiet -WarningAction SilentlyContinue) {
                return $true
            }
        }
        return $false
    }
    catch {
        return $false
    }
}

function Get-UpdateConfiguration {
    <#
    .SYNOPSIS
    Loads update configuration from file
    #>
    try {
        if (Test-Path $script:UpdateConfigFile) {
            $config = Get-Content $script:UpdateConfigFile -Raw | ConvertFrom-Json
            return $config
        }
        else {
            Write-LogMessage "Update configuration not found, using defaults" -Level Warning
            return @{
                UpdateServer = $UpdateServer
                AutoUpdate = $true
                CheckInterval = $script:UpdateCheckInterval
                UpdateChannel = "stable"
                Enabled = $true
            }
        }
    }
    catch {
        Write-LogMessage "Error loading update configuration: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Get-VersionInformation {
    <#
    .SYNOPSIS
    Gets current version information
    #>
    try {
        if (Test-Path $script:VersionFile) {
            $versionInfo = Get-Content $script:VersionFile -Raw | ConvertFrom-Json
            return $versionInfo
        }
        else {
            return @{
                CurrentVersion = $script:CurrentVersion
                LastUpdateCheck = Get-Date
                UpdateChannel = "stable"
                InstallDate = Get-Date
                UpdateHistory = @()
            }
        }
    }
    catch {
        Write-LogMessage "Error loading version information: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-UpdateAvailable {
    <#
    .SYNOPSIS
    Checks if updates are available from the server
    #>
    try {
        if (-not (Test-InternetConnection)) {
            Write-LogMessage "No internet connection available for update check" -Level Warning
            return $false
        }
        
        $updateConfig = Get-UpdateConfiguration
        if (-not $updateConfig -or -not $updateConfig.Enabled) {
            Write-LogMessage "Updates are disabled" -Level Info
            return $false
        }
        
        $versionInfo = Get-VersionInformation
        $currentVersion = [version]$versionInfo.CurrentVersion
        
        # Simulate update check (replace with actual server call)
        $latestVersion = Get-LatestVersionFromServer -UpdateServer $updateConfig.UpdateServer
        
        if ($latestVersion -and ([version]$latestVersion -gt $currentVersion)) {
            Write-LogMessage "Update available: $latestVersion (current: $($currentVersion))" -Level Info
            return @{
                Available = $true
                LatestVersion = $latestVersion
                CurrentVersion = $currentVersion.ToString()
                UpdateInfo = "New version available with improvements and bug fixes"
            }
        }
        else {
            Write-LogMessage "No updates available" -Level Info
            return @{
                Available = $false
                LatestVersion = $currentVersion.ToString()
                CurrentVersion = $currentVersion.ToString()
            }
        }
    }
    catch {
        Write-LogMessage "Error checking for updates: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-LatestVersionFromServer {
    param([string]$UpdateServer)
    
    try {
        # This is a mock implementation - replace with actual server API call
        # For now, we'll simulate by checking a local file or remote URL
        
        # Example GitHub API call (if hosting on GitHub):
        # $apiUrl = "https://api.github.com/repos/yourusername/pc-optimization-suite/releases/latest"
        # $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        # return $response.tag_name.TrimStart('v')
        
        # For demonstration, return a newer version
        return "2.0.2"
    }
    catch {
        Write-LogMessage "Error contacting update server: $($_.Exception.Message)" -Level Warning
        return $null
    }
}

function Start-UpdateDownload {
    <#
    .SYNOPSIS
    Downloads and installs updates
    #>
    param(
        [string]$Version,
        [string]$UpdateServer
    )
    
    try {
        Write-LogMessage "Starting update download for version $Version" -Level Info
        
        # Create backup of current version
        $backupResult = New-SystemBackup
        if (-not $backupResult) {
            Write-LogMessage "Backup creation failed - aborting update" -Level Error
            return $false
        }
        
        # Download update package
        $downloadResult = Invoke-UpdateDownload -Version $Version -UpdateServer $UpdateServer
        if (-not $downloadResult) {
            Write-LogMessage "Update download failed" -Level Error
            return $false
        }
        
        # Install update
        $installResult = Install-UpdatePackage -PackagePath $downloadResult
        if (-not $installResult) {
            Write-LogMessage "Update installation failed - restoring backup" -Level Error
            Restore-SystemBackup -BackupPath $backupResult
            return $false
        }
        
        # Update version information
        Update-VersionInformation -NewVersion $Version
        
        Write-LogMessage "Update completed successfully to version $Version" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Update process failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Invoke-UpdateDownload {
    param(
        [string]$Version,
        [string]$UpdateServer
    )
    
    try {
        $downloadUrl = "$UpdateServer/download/$Version"
        $downloadPath = Join-Path $script:UpdatePath "update_$Version.zip"
        
        Write-LogMessage "Downloading update from: $downloadUrl" -Level Info
        
        # Mock download - replace with actual download logic
        # Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
        
        # For demonstration, create a mock update file
        @{
            Version = $Version
            Files = $script:RequiredFiles
            UpdateDate = Get-Date
        } | ConvertTo-Json | Set-Content $downloadPath -Encoding UTF8
        
        if (Test-Path $downloadPath) {
            Write-LogMessage "Update downloaded successfully" -Level Success
            return $downloadPath
        }
        else {
            Write-LogMessage "Download verification failed" -Level Error
            return $null
        }
    }
    catch {
        Write-LogMessage "Download error: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Install-UpdatePackage {
    param([string]$PackagePath)
    
    try {
        Write-LogMessage "Installing update package: $PackagePath" -Level Info
        
        # Extract and install files (mock implementation)
        # In a real scenario, you would:
        # 1. Extract the zip file
        # 2. Validate file signatures
        # 3. Stop any running processes
        # 4. Replace files
        # 5. Update configurations
        
        Start-Sleep -Seconds 2 # Simulate installation time
        
        Write-LogMessage "Update package installed successfully" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Installation error: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function New-SystemBackup {
    <#
    .SYNOPSIS
    Creates a backup of current system files
    #>
    try {
        $backupName = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $backupDir = Join-Path $script:BackupPath $backupName
        
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        
        foreach ($file in $script:RequiredFiles) {
            $sourcePath = Join-Path $script:InstallPath $file
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath -Destination $backupDir -Force
            }
        }
        
        # Copy configuration files
        if (Test-Path $script:ConfigPath) {
            Copy-Item $script:ConfigPath -Destination (Join-Path $backupDir "Config") -Recurse -Force
        }
        
        Write-LogMessage "Backup created: $backupDir" -Level Success
        return $backupDir
    }
    catch {
        Write-LogMessage "Backup creation failed: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Restore-SystemBackup {
    param([string]$BackupPath)
    
    try {
        Write-LogMessage "Restoring system from backup: $BackupPath" -Level Info
        
        if (-not (Test-Path $BackupPath)) {
            Write-LogMessage "Backup path not found: $BackupPath" -Level Error
            return $false
        }
        
        # Restore files
        Get-ChildItem $BackupPath -File | ForEach-Object {
            Copy-Item $_.FullName -Destination $script:InstallPath -Force
        }
        
        # Restore configuration
        $configBackup = Join-Path $BackupPath "Config"
        if (Test-Path $configBackup) {
            Copy-Item $configBackup -Destination $script:ConfigPath -Recurse -Force
        }
        
        Write-LogMessage "System restored from backup successfully" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Restore failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Update-VersionInformation {
    param([string]$NewVersion)
    
    try {
        $versionInfo = Get-VersionInformation
        $versionInfo.CurrentVersion = $NewVersion
        $versionInfo.LastUpdateCheck = Get-Date
        
        # Add to update history
        $updateEntry = @{
            Version = $NewVersion
            UpdateDate = Get-Date
            UpdateType = "Automatic"
        }
        
        if (-not $versionInfo.UpdateHistory) {
            $versionInfo.UpdateHistory = @()
        }
        $versionInfo.UpdateHistory += $updateEntry
        
        # Keep only last 10 entries
        if ($versionInfo.UpdateHistory.Count -gt 10) {
            $versionInfo.UpdateHistory = $versionInfo.UpdateHistory | Select-Object -Last 10
        }
        
        $versionInfo | ConvertTo-Json -Depth 3 | Set-Content $script:VersionFile -Encoding UTF8
        Write-LogMessage "Version information updated to $NewVersion" -Level Success
    }
    catch {
        Write-LogMessage "Error updating version information: $($_.Exception.Message)" -Level Error
    }
}

#endregion

#region Distribution Functions

function New-DistributionPackage {
    <#
    .SYNOPSIS
    Creates a distribution package for sharing with others
    #>
    try {
        Write-LogMessage "Creating distribution package..." -Level Info
        
        $distroName = "PCOptimizationSuite_v$($script:CurrentVersion)_$(Get-Date -Format 'yyyyMMdd')"
        $distroPath = Join-Path (Split-Path $script:InstallPath) $distroName
        
        if (Test-Path $distroPath) {
            Remove-Item $distroPath -Recurse -Force
        }
        
        New-Item -Path $distroPath -ItemType Directory -Force | Out-Null
        
        # Copy all required files
        foreach ($file in $script:RequiredFiles) {
            $sourcePath = Join-Path $script:InstallPath $file
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath -Destination $distroPath -Force
            }
        }
        
        # Copy launcher
        Copy-Item $PSCommandPath -Destination $distroPath -Force
        
        # Create installation readme
        $readmeContent = @"
# PC Optimization Suite v$($script:CurrentVersion)

## Installation Instructions

1. Extract all files to a folder on your computer
2. Right-click on 'PCOptimizationLauncher.ps1' and select 'Run with PowerShell'
3. If prompted about execution policy, choose 'Yes' or run as administrator
4. The program will automatically set up and check for updates

## System Requirements

- Windows 10/11
- PowerShell 5.1 or higher
- Administrator privileges (recommended)
- Internet connection (for updates)

## First Run

On first run, the program will:
- Create necessary directories
- Set up configuration files
- Check for updates
- Launch the main interface

## Getting Help

- Check the Logs folder for detailed information
- Configuration files are stored in the Config folder
- Backups are automatically created in the Backups folder

## Features

- Automatic driver updates
- System optimization
- Performance monitoring
- Registry cleaning
- Cache cleanup
- Gaming optimization
- Automatic updates

## Contact

For support or updates, visit: [Your Website/GitHub]

Generated: $(Get-Date)
"@
        
        $readmeContent | Set-Content (Join-Path $distroPath "README.txt") -Encoding UTF8
        
        # Create batch file for easy launching
        $batchContent = @"
@echo off
title PC Optimization Suite Launcher
echo Starting PC Optimization Suite...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PCOptimizationLauncher.ps1"
pause
"@
        $batchContent | Set-Content (Join-Path $distroPath "Launch.bat") -Encoding ASCII
        
        # Create ZIP package
        $zipPath = "$distroPath.zip"
        if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
            Compress-Archive -Path $distroPath -DestinationPath $zipPath -Force
            Write-LogMessage "Distribution package created: $zipPath" -Level Success
            
            # Clean up temporary directory
            Remove-Item $distroPath -Recurse -Force
            
            return $zipPath
        }
        else {
            Write-LogMessage "Distribution package created: $distroPath" -Level Success
            return $distroPath
        }
    }
    catch {
        Write-LogMessage "Error creating distribution package: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-SystemIntegrity {
    <#
    .SYNOPSIS
    Verifies all required files are present and functional
    #>
    $missing = @()
    $errors = @()
    
    foreach ($file in $script:RequiredFiles) {
        $filePath = Join-Path $script:InstallPath $file
        if (-not (Test-Path $filePath)) {
            $missing += $file
        }
        else {
            # Test PowerShell syntax
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $filePath -Raw), [ref]$null)
            }
            catch {
                $errors += "$file`: $($_.Exception.Message)"
            }
        }
    }
    
    $result = @{
        AllFilesPresent = ($missing.Count -eq 0)
        MissingFiles = $missing
        SyntaxErrors = $errors
        TotalFiles = $script:RequiredFiles.Count
        ValidFiles = $script:RequiredFiles.Count - $missing.Count - $errors.Count
    }
    
    if ($result.AllFilesPresent -and $errors.Count -eq 0) {
        Write-LogMessage "System integrity check passed" -Level Success
    }
    else {
        Write-LogMessage "System integrity issues found" -Level Warning
        if ($missing.Count -gt 0) {
            Write-LogMessage "Missing files: $($missing -join ', ')" -Level Error
        }
        if ($errors.Count -gt 0) {
            Write-LogMessage "Syntax errors found in: $($errors -join '; ')" -Level Error
        }
    }
    
    return $result
}

#endregion

#region User Interface Functions

function Show-WelcomeBanner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           🚀 PC OPTIMIZATION SUITE LAUNCHER 🚀               ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║         Automatic Updates • Distribution • Management        ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║                   Version $($script:CurrentVersion.PadRight(18))                    ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-UpdatePrompt {
    param([hashtable]$UpdateInfo)
    
    Write-Host "🔄 UPDATE AVAILABLE" -ForegroundColor Yellow
    Write-Host "Current Version: $($UpdateInfo.CurrentVersion)" -ForegroundColor White
    Write-Host "Latest Version:  $($UpdateInfo.LatestVersion)" -ForegroundColor Green
    Write-Host "Update Info:     $($UpdateInfo.UpdateInfo)" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Would you like to update now? (Y/N)"
    return ($choice -match '^[Yy]')
}

function Show-FirstRunSetup {
    Write-Host "🎉 Welcome to PC Optimization Suite!" -ForegroundColor Green
    Write-Host ""
    Write-Host "This appears to be your first time running the program." -ForegroundColor White
    Write-Host "Let's set up a few things to get you started:" -ForegroundColor White
    Write-Host ""
    
    # Auto-update preference
    Write-Host "1. Automatic Updates" -ForegroundColor Yellow
    $autoUpdate = Read-Host "Enable automatic updates? (Y/N) [Y]"
    $autoUpdateEnabled = ($autoUpdate -eq '' -or $autoUpdate -match '^[Yy]')
    
    # Telemetry preference
    Write-Host ""
    Write-Host "2. Usage Analytics" -ForegroundColor Yellow
    Write-Host "   Help improve the software by sending anonymous usage data" -ForegroundColor Gray
    $telemetry = Read-Host "Enable usage analytics? (Y/N) [N]"
    $telemetryEnabled = ($telemetry -match '^[Yy]')
    
    # Desktop shortcut
    Write-Host ""
    Write-Host "3. Desktop Shortcut" -ForegroundColor Yellow
    $shortcut = Read-Host "Create desktop shortcut? (Y/N) [Y]"
    $createShortcut = ($shortcut -eq '' -or $shortcut -match '^[Yy]')
    
    # Save preferences
    $userConfig = @{
        FirstRun = $false
        AutoUpdate = $autoUpdateEnabled
        TelemetryEnabled = $telemetryEnabled
        SetupCompleted = Get-Date
        DesktopShortcut = $createShortcut
    }
    
    $userConfig | ConvertTo-Json -Depth 3 | Set-Content $script:UserConfigFile -Encoding UTF8
    
    if ($createShortcut) {
        New-DesktopShortcut
    }
    
    Write-Host ""
    Write-Host "✅ Setup completed! Launching PC Optimization Suite..." -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function New-DesktopShortcut {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "PC Optimization Suite.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $shortcut.WorkingDirectory = $script:InstallPath
        $shortcut.IconLocation = "shell32.dll,21"
        $shortcut.Description = "PC Optimization Suite - System Performance Tool"
        $shortcut.Save()
        
        Write-LogMessage "Desktop shortcut created" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Failed to create desktop shortcut: $($_.Exception.Message)" -Level Warning
        return $false
    }
}

#endregion

#region Main Execution Logic

function Start-MainProgram {
    <#
    .SYNOPSIS
    Launches the main PC Optimization Suite program
    #>
    try {
        $mainScript = Join-Path $script:InstallPath "DriverUpdaterManager.ps1"
        if (Test-Path $mainScript) {
            Write-LogMessage "Launching main program: $mainScript" -Level Info
            & $mainScript
        }
        else {
            Write-LogMessage "Main program not found: $mainScript" -Level Error
            Write-Host "❌ Main program file not found. Please reinstall the application." -ForegroundColor Red
            Read-Host "Press Enter to exit"
        }
    }
    catch {
        Write-LogMessage "Error launching main program: $($_.Exception.Message)" -Level Error
        Write-Host "❌ Error launching main program. Check logs for details." -ForegroundColor Red
        Read-Host "Press Enter to exit"
    }
}

# Main execution starts here
try {
    Show-WelcomeBanner
    
    # Handle command line parameters
    if ($Version) {
        $versionInfo = Get-VersionInformation
        Write-Host "PC Optimization Suite Launcher" -ForegroundColor Cyan
        Write-Host "Current Version: $($versionInfo.CurrentVersion)" -ForegroundColor White
        Write-Host "Install Date: $($versionInfo.InstallDate)" -ForegroundColor Gray
        Write-Host "Last Update Check: $($versionInfo.LastUpdateCheck)" -ForegroundColor Gray
        return
    }
    
    # Initialize system
    Initialize-DirectoryStructure
    
    # Check if this is first run
    $userConfig = $null
    if (Test-Path $script:UserConfigFile) {
        $userConfig = Get-Content $script:UserConfigFile -Raw | ConvertFrom-Json
    }
    
    if (-not $userConfig -or $userConfig.FirstRun) {
        Initialize-Configuration
        Show-FirstRunSetup
    }
    
    # System integrity check
    Write-LogMessage "Performing system integrity check..." -Level Info
    $integrityResult = Test-SystemIntegrity
    
    if (-not $integrityResult.AllFilesPresent) {
        Write-Host "⚠️  System integrity check failed!" -ForegroundColor Red
        Write-Host "Missing files detected. Please reinstall the application." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Missing files:" -ForegroundColor Red
        foreach ($file in $integrityResult.MissingFiles) {
            Write-Host "  • $file" -ForegroundColor Yellow
        }
        Read-Host "Press Enter to exit"
        return
    }
    
    # Check for updates (unless disabled)
    if ($CheckUpdates -or $ForceUpdate -or (-not $userConfig -or $userConfig.AutoUpdate)) {
        Write-LogMessage "Checking for updates..." -Level Info
        $updateCheck = Test-UpdateAvailable
        
        if ($updateCheck -and $updateCheck.Available) {
            if ($ForceUpdate -or (Show-UpdatePrompt -UpdateInfo $updateCheck)) {
                $updateResult = Start-UpdateDownload -Version $updateCheck.LatestVersion -UpdateServer (Get-UpdateConfiguration).UpdateServer
                
                if ($updateResult) {
                    Write-Host "✅ Update completed successfully!" -ForegroundColor Green
                    Write-Host "Restarting application..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 3
                    & $PSCommandPath
                    return
                }
                else {
                    Write-Host "❌ Update failed. Continuing with current version." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
        }
        elseif ($CheckUpdates) {
            Write-Host "✅ You have the latest version ($($updateCheck.CurrentVersion))" -ForegroundColor Green
            Read-Host "Press Enter to continue"
        }
    }
    
    # If we're only checking updates, exit here
    if ($CheckUpdates) {
        return
    }
    
    # Launch main program
    Start-MainProgram
}
catch {
    Write-LogMessage "Critical launcher error: $($_.Exception.Message)" -Level Error
    Write-Host "❌ A critical error occurred in the launcher." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check the logs in: $script:LogPath" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

#endregion