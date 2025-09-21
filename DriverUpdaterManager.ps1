<#
.SYNOPSIS
    Driver Updater Manager - Main interface for PC optimization and driver management

.DESCRIPTION
    Comprehensive driver and system management tool with interactive interface.
    Integrates AdvancedDriverUpdater.ps1, SystemLogger.ps1, and PCOptimizationSuite.ps1

.PARAMETER Install
    Install the driver updater as a service

.PARAMETER Uninstall
    Uninstall the driver updater service

.PARAMETER Configure
    Open configuration interface

.PARAMETER RunScan
    Run driver scan only

.PARAMETER RunUpdate
    Run driver update process

.PARAMETER Schedule
    Setup scheduled tasks

.AUTHOR
    PC Optimization Suite v2.0

.EXAMPLE
    .\DriverUpdaterManager.ps1
    .\DriverUpdaterManager.ps1 -RunScan
    .\DriverUpdaterManager.ps1 -Configure
#>

param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Configure,
    [switch]$RunScan,
    [switch]$RunUpdate,
    [switch]$Schedule
)

# Initialize script variables
$script:ScriptRoot = $PSScriptRoot
$script:LogPath = Join-Path $script:ScriptRoot "Logs"
$script:ConfigFile = Join-Path $script:ScriptRoot "DriverUpdaterConfig.ini"

# Import SystemLogger if available
if (Test-Path (Join-Path $script:ScriptRoot "SystemLogger.ps1")) {
    try {
        . (Join-Path $script:ScriptRoot "SystemLogger.ps1")
        Write-Log "DriverUpdaterManager started" -Level Info
    }
    catch {
        Write-Warning "Could not load SystemLogger: $($_.Exception.Message)"
    }
}
else {
    function Write-Log {
        param([string]$Message, [string]$Level = "Info")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [$Level] $Message"
    }
}

#region Helper Functions

function Test-AdminPrivilege {
    <#
    .SYNOPSIS
    Tests if current session has administrator privileges
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-ColorOutput {
    <#
    .SYNOPSIS
    Writes colored output to console
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ConsoleColor]$ForegroundColor = "White",
        [ConsoleColor]$BackgroundColor = "Black"
    )
    
    Write-Host -Object $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
}

function Show-Banner {
    <#
    .SYNOPSIS
    Displays the main application banner
    #>
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-ColorOutput "║           🚀 DRIVER UPDATER MANAGER v2.0 🚀                  ║" -ForegroundColor Cyan
    Write-ColorOutput "║                                                              ║" -ForegroundColor Cyan
    Write-ColorOutput "║  • Advanced Driver Updates    • System Optimization         ║" -ForegroundColor White
    Write-ColorOutput "║  • Health Monitoring          • Performance Boost           ║" -ForegroundColor White
    Write-ColorOutput "║  • Intelligent Recovery       • Automated Maintenance       ║" -ForegroundColor White
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-AdminPrivilege)) {
        Write-ColorOutput "⚠️  WARNING: Running without administrator privileges" -ForegroundColor Yellow
        Write-ColorOutput "   Some features may not work properly" -ForegroundColor Yellow
        Write-Host ""
    }
}

function New-DesktopShortcut {
    <#
    .SYNOPSIS
    Creates a desktop shortcut for the application
    #>
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "Driver Updater Manager.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $shortcut.WorkingDirectory = $script:ScriptRoot
        $shortcut.IconLocation = "shell32.dll,21"
        $shortcut.Description = "Driver Updater Manager - System Optimization Tool"
        $shortcut.Save()
        
        Write-Log "Desktop shortcut created successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to create desktop shortcut: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-Dependencies {
    <#
    .SYNOPSIS
    Tests for required dependencies and files
    #>
    $dependencies = @{
        "AdvancedDriverUpdater.ps1" = "Driver update engine"
        "SystemLogger.ps1"          = "Logging system"
    }
    
    $missingDeps = @()
    
    foreach ($dep in $dependencies.GetEnumerator()) {
        $filePath = Join-Path $script:ScriptRoot $dep.Key
        if (-not (Test-Path $filePath)) {
            $missingDeps += "$($dep.Key) - $($dep.Value)"
        }
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-ColorOutput "❌ Missing Dependencies:" -ForegroundColor Red
        foreach ($dep in $missingDeps) {
            Write-ColorOutput "   • $dep" -ForegroundColor Yellow
        }
        return $false
    }
    
    Write-ColorOutput "✅ All dependencies found" -ForegroundColor Green
    return $true
}

#endregion

#region Main Functions

function Start-DriverScan {
    <#
    .SYNOPSIS
    Initiates a driver scan operation
    #>
    Write-Log "Starting driver scan..." -Level Info
    
    if (Test-Path (Join-Path $script:ScriptRoot "AdvancedDriverUpdater.ps1")) {
        try {
            Write-ColorOutput "🔍 Scanning for outdated drivers..." -ForegroundColor Cyan
            & (Join-Path $script:ScriptRoot "AdvancedDriverUpdater.ps1") -ScanOnly
            Write-Log "Driver scan completed" -Level Success
        }
        catch {
            Write-Log "Driver scan failed: $($_.Exception.Message)" -Level Error
            Write-ColorOutput "❌ Driver scan failed. Check logs for details." -ForegroundColor Red
        }
    }
    else {
        Write-ColorOutput "❌ AdvancedDriverUpdater.ps1 not found" -ForegroundColor Red
    }
}

function Start-DriverUpdate {
    <#
    .SYNOPSIS
    Initiates a driver update operation
    #>
    Write-Log "Starting driver update..." -Level Info
    
    if (Test-Path (Join-Path $script:ScriptRoot "AdvancedDriverUpdater.ps1")) {
        try {
            Write-ColorOutput "🔄 Updating system drivers..." -ForegroundColor Cyan
            & (Join-Path $script:ScriptRoot "AdvancedDriverUpdater.ps1")
            Write-Log "Driver update completed" -Level Success
        }
        catch {
            Write-Log "Driver update failed: $($_.Exception.Message)" -Level Error
            Write-ColorOutput "❌ Driver update failed. Check logs for details." -ForegroundColor Red
        }
    }
    else {
        Write-ColorOutput "❌ AdvancedDriverUpdater.ps1 not found" -ForegroundColor Red
    }
}

function Start-SystemOptimization {
    <#
    .SYNOPSIS
    Launches the system optimization suite
    #>
    Write-Log "Starting system optimization..." -Level Info
    
    if (Test-Path (Join-Path $script:ScriptRoot "PCOptimizationSuite.ps1")) {
        try {
            Write-ColorOutput "⚡ Optimizing system performance..." -ForegroundColor Cyan
            & (Join-Path $script:ScriptRoot "PCOptimizationSuite.ps1") -FullOptimization
            Write-Log "System optimization completed" -Level Success
        }
        catch {
            Write-Log "System optimization failed: $($_.Exception.Message)" -Level Error
            Write-ColorOutput "❌ System optimization failed. Check logs for details." -ForegroundColor Red
        }
    }
    else {
        Write-ColorOutput "⚠️  PCOptimizationSuite.ps1 not found - creating basic optimization..." -ForegroundColor Yellow
        Start-BasicOptimization
    }
}

function Start-BasicOptimization {
    <#
    .SYNOPSIS
    Performs basic system optimization when full suite is unavailable
    #>
    Write-ColorOutput "🔧 Running basic system optimization..." -ForegroundColor Cyan
    
    try {
        # Clear temporary files
        Write-ColorOutput "   • Clearing temporary files..." -ForegroundColor White
        $tempPaths = @("$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:LOCALAPPDATA\Temp\*")
        foreach ($path in $tempPaths) {
            if (Test-Path (Split-Path $path)) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Clear browser caches
        Write-ColorOutput "   • Clearing browser caches..." -ForegroundColor White
        $cachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
            "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2\*"
        )
        foreach ($path in $cachePaths) {
            if (Test-Path (Split-Path $path)) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Run disk cleanup
        Write-ColorOutput "   • Running system cleanup..." -ForegroundColor White
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        
        Write-ColorOutput "✅ Basic optimization completed" -ForegroundColor Green
        Write-Log "Basic system optimization completed" -Level Success
    }
    catch {
        Write-Log "Basic optimization failed: $($_.Exception.Message)" -Level Error
        Write-ColorOutput "❌ Basic optimization failed" -ForegroundColor Red
    }
}

function Show-SystemHealth {
    <#
    .SYNOPSIS
    Displays current system health information
    #>
    Write-ColorOutput "📊 System Health Report" -ForegroundColor Cyan
    Write-ColorOutput "========================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Memory information
        $memory = Get-CimInstance Win32_OperatingSystem
        $freeMemGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $totalMemGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $memoryUsagePercent = [math]::Round((($totalMemGB - $freeMemGB) / $totalMemGB) * 100, 1)
        
        Write-ColorOutput "💾 Memory Usage: $memoryUsagePercent% ($freeMemGB GB free of $totalMemGB GB)" -ForegroundColor White
        
        # Disk space
        $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($disk in $disks) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
            $usagePercent = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)
            
            $color = if ($usagePercent -gt 90) { "Red" } elseif ($usagePercent -gt 80) { "Yellow" } else { "Green" }
            Write-ColorOutput "💿 Drive $($disk.DeviceID) Usage: $usagePercent% ($freeSpaceGB GB free of $totalSpaceGB GB)" -ForegroundColor $color
        }
        
        # Uptime
        $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        Write-ColorOutput "⏱️  System Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor White
        
        # Services
        $stoppedServices = Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
        if ($stoppedServices.Count -gt 0) {
            Write-ColorOutput "⚠️  $($stoppedServices.Count) automatic services are stopped" -ForegroundColor Yellow
        }
        else {
            Write-ColorOutput "✅ All automatic services are running" -ForegroundColor Green
        }
        
        Write-Host ""
    }
    catch {
        Write-Log "Error generating system health report: $($_.Exception.Message)" -Level Error
        Write-ColorOutput "❌ Could not generate complete health report" -ForegroundColor Red
    }
}

function Show-ReportAndLog {
    <#
    .SYNOPSIS
    Displays recent logs and reports
    #>
    Write-ColorOutput "📋 Recent Logs and Reports" -ForegroundColor Cyan
    Write-ColorOutput "============================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $script:LogPath)) {
        Write-ColorOutput "📁 No logs directory found. Creating..." -ForegroundColor Yellow
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
        return
    }
    
    $logFiles = Get-ChildItem -Path $script:LogPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    
    if ($logFiles.Count -eq 0) {
        Write-ColorOutput "📄 No log files found" -ForegroundColor Yellow
        return
    }
    
    foreach ($logFile in $logFiles) {
        Write-ColorOutput "📄 $($logFile.Name) - $(Get-Date $logFile.LastWriteTime -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
        
        # Show last few lines of each log
        $lastLines = Get-Content $logFile.FullName -Tail 3 -ErrorAction SilentlyContinue
        foreach ($line in $lastLines) {
            Write-Host "   $line" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

function Show-Configuration {
    <#
    .SYNOPSIS
    Shows and allows modification of configuration settings
    #>
    Write-ColorOutput "⚙️  Configuration Settings" -ForegroundColor Cyan
    Write-ColorOutput "===========================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-ColorOutput "Current Settings:" -ForegroundColor White
    Write-ColorOutput "• Script Root: $script:ScriptRoot" -ForegroundColor Gray
    Write-ColorOutput "• Log Path: $script:LogPath" -ForegroundColor Gray
    Write-ColorOutput "• Config File: $script:ConfigFile" -ForegroundColor Gray
    Write-Host ""
    
    # Configuration options
    do {
        Write-ColorOutput "Configuration Options:" -ForegroundColor Yellow
        Write-ColorOutput "1. Create Desktop Shortcut" -ForegroundColor White
        Write-ColorOutput "2. Set Automatic Startup" -ForegroundColor White
        Write-ColorOutput "3. Configure Logging Level" -ForegroundColor White
        Write-ColorOutput "4. Reset to Defaults" -ForegroundColor White
        Write-ColorOutput "5. Return to Main Menu" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Select option (1-5)"
        
        switch ($choice) {
            "1" {
                if (New-DesktopShortcut) {
                    Write-ColorOutput "✅ Desktop shortcut created successfully" -ForegroundColor Green
                }
                else {
                    Write-ColorOutput "❌ Failed to create desktop shortcut" -ForegroundColor Red
                }
                Write-Host ""
            }
            "2" {
                Write-ColorOutput "🔄 Automatic startup configuration not yet implemented" -ForegroundColor Yellow
                Write-Host ""
            }
            "3" {
                Write-ColorOutput "📝 Logging level configuration not yet implemented" -ForegroundColor Yellow
                Write-Host ""
            }
            "4" {
                Write-ColorOutput "♻️  Reset to defaults not yet implemented" -ForegroundColor Yellow
                Write-Host ""
            }
            "5" {
                return
            }
            default {
                Write-ColorOutput "❌ Invalid selection. Please choose 1-5." -ForegroundColor Red
                Write-Host ""
            }
        }
    } while ($choice -ne "5")
}

function Remove-OldLogFile {
    <#
    .SYNOPSIS
    Cleans up old log files
    #>
    try {
        if (-not (Test-Path $script:LogPath)) {
            return
        }
        
        $cutoffDate = (Get-Date).AddDays(-30)
        $oldLogs = Get-ChildItem -Path $script:LogPath -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldLogs.Count -gt 0) {
            Write-ColorOutput "🧹 Cleaning up $($oldLogs.Count) old log files..." -ForegroundColor Yellow
            $oldLogs | Remove-Item -Force
            Write-Log "Cleaned up $($oldLogs.Count) old log files" -Level Info
        }
    }
    catch {
        Write-Log "Error cleaning up log files: $($_.Exception.Message)" -Level Error
    }
}

function Start-DeepDiagnostic {
    <#
    .SYNOPSIS
    Performs comprehensive system diagnostics
    #>
    Write-ColorOutput "🔬 Deep System Diagnostics" -ForegroundColor Cyan
    Write-ColorOutput "============================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-ColorOutput "Running comprehensive system analysis..." -ForegroundColor Yellow
    
    try {
        # System file check
        Write-ColorOutput "🔍 Checking system file integrity..." -ForegroundColor White
        $sfcResult = & sfc /scannow 2>&1
        
        # Memory diagnostic
        Write-ColorOutput "🧠 Checking memory health..." -ForegroundColor White
        $memoryErrors = Get-WinEvent -FilterHashtable @{LogName = "System"; ID = 1001 } -MaxEvents 5 -ErrorAction SilentlyContinue
        
        # Log memory health status
        if ($memoryErrors -and $memoryErrors.Count -gt 0) {
            Write-ColorOutput "⚠️ Found $($memoryErrors.Count) memory-related events" -ForegroundColor Yellow
        }
        else {
            Write-ColorOutput "✓ No critical memory errors found" -ForegroundColor Green
        }
        
        # Disk health
        Write-ColorOutput "💿 Checking disk health..." -ForegroundColor White
        $diskHealth = Get-PhysicalDisk | Select-Object DeviceID, HealthStatus, OperationalStatus
        
        foreach ($disk in $diskHealth) {
            $healthColor = if ($disk.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
            Write-ColorOutput "   Disk $($disk.DeviceID): $($disk.HealthStatus) ($($disk.OperationalStatus))" -ForegroundColor $healthColor
        }
        
        Write-ColorOutput "✅ Deep diagnostics completed" -ForegroundColor Green
        Write-Log "Deep diagnostics completed successfully" -Level Success
    }
    catch {
        Write-Log "Deep diagnostics failed: $($_.Exception.Message)" -Level Error
        Write-ColorOutput "❌ Deep diagnostics encountered errors" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-MainMenu {
    <#
    .SYNOPSIS
    Displays the main interactive menu
    #>
    do {
        Show-Banner
        Show-SystemHealth
        Write-Host ""
        
        Write-ColorOutput "Main Menu:" -ForegroundColor Yellow
        Write-ColorOutput "1. 🔍 Scan for Driver Updates" -ForegroundColor White
        Write-ColorOutput "2. 🔄 Update System Drivers" -ForegroundColor White
        Write-ColorOutput "3. ⚡ System Optimization" -ForegroundColor White
        Write-ColorOutput "4. 📊 View System Health" -ForegroundColor White
        Write-ColorOutput "5. 📋 View Logs & Reports" -ForegroundColor White
        Write-ColorOutput "6. ⚙️  Configuration" -ForegroundColor White
        Write-ColorOutput "7. 🔬 Deep Diagnostics" -ForegroundColor White
        Write-ColorOutput "8. 🧹 Clean Old Logs" -ForegroundColor White
        Write-ColorOutput "9. ❌ Exit" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-9)"
        
        switch ($choice) {
            "1" {
                Start-DriverScan
                Read-Host "Press Enter to continue"
            }
            "2" {
                Start-DriverUpdate
                Read-Host "Press Enter to continue"
            }
            "3" {
                Start-SystemOptimization
                Read-Host "Press Enter to continue"
            }
            "4" {
                Show-SystemHealth
                Read-Host "Press Enter to continue"
            }
            "5" {
                Show-ReportAndLog
                Read-Host "Press Enter to continue"
            }
            "6" {
                Show-Configuration
            }
            "7" {
                Start-DeepDiagnostic
            }
            "8" {
                Remove-OldLogFile
                Write-ColorOutput "✅ Log cleanup completed" -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
            "9" {
                Write-ColorOutput "👋 Thank you for using Driver Updater Manager!" -ForegroundColor Cyan
                Write-Log "DriverUpdaterManager session ended" -Level Info
                return
            }
            default {
                Write-ColorOutput "❌ Invalid selection. Please choose 1-9." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

#endregion

#region Main Execution

try {
    # Handle command line parameters
    if ($Install) {
        Write-ColorOutput "📦 Install mode not yet implemented" -ForegroundColor Yellow
        return
    }
    elseif ($Uninstall) {
        Write-ColorOutput "🗑️  Uninstall mode not yet implemented" -ForegroundColor Yellow
        return
    }
    elseif ($Configure) {
        Show-Banner
        Show-Configuration
        return
    }
    elseif ($RunScan) {
        Show-Banner
        Start-DriverScan
        return
    }
    elseif ($RunUpdate) {
        Show-Banner
        Start-DriverUpdate
        return
    }
    elseif ($Schedule) {
        Write-ColorOutput "📅 Schedule mode not yet implemented" -ForegroundColor Yellow
        return
    }
    else {
        # Interactive mode
        if (-not (Test-Dependencies)) {
            Write-Host ""
            Write-ColorOutput "⚠️  Some components are missing. Basic functionality will be available." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
        
        Show-MainMenu
    }
}
catch {
    Write-Log "Critical error in DriverUpdaterManager: $($_.Exception.Message)" -Level Error
    Write-ColorOutput "❌ A critical error occurred. Check the logs for details." -ForegroundColor Red
    if ($script:LogPath -and (Test-Path $script:LogPath)) {
        Write-ColorOutput "Log location: $script:LogPath" -ForegroundColor Gray
    }
    Read-Host "Press Enter to exit"
    exit 1
}

#endregion
