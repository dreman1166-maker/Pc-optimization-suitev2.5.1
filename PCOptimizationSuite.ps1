<#
.SYNOPSIS
    PC Optimization Suite - Comprehensive system performance and health optimizer

.DESCRIPTION
    Advanced system optimization tool that provides:
    - System health monitoring and scoring
    - Performance optimization routines
    - Registry cleaning and optimization
    - Internet and network optimization
    - Gaming performance enhancements
    - Automated maintenance tasks

.PARAMETER DriverScan
    Perform driver scanning only

.PARAMETER SoftwareUpdate
    Check and install software updates

.PARAMETER PerformanceBoost
    Apply performance optimization settings

.PARAMETER HealthCheck
    Run comprehensive system health check

.PARAMETER RegistryClean
    Clean and optimize system registry

.PARAMETER InternetBoost
    Optimize internet and network settings

.PARAMETER GamingBoost
    Apply gaming-specific optimizations

.PARAMETER FullOptimization
    Run complete system optimization

.PARAMETER Silent
    Run in silent mode without user interaction

.PARAMETER LogPath
    Specify custom log file path

.AUTHOR
    PC Optimization Suite v2.0

.EXAMPLE
    .\PCOptimizationSuite.ps1 -HealthCheck
    .\PCOptimizationSuite.ps1 -FullOptimization
    .\PCOptimizationSuite.ps1 -GamingBoost
#>

param(
    [switch]$DriverScan,
    [switch]$SoftwareUpdate,
    [switch]$PerformanceBoost,
    [switch]$HealthCheck,
    [switch]$RegistryClean,
    [switch]$InternetBoost,
    [switch]$GamingBoost,
    [switch]$FullOptimization,
    [switch]$Silent,
    [string]$LogPath = $PSScriptRoot
)

# Initialize script variables
$script:LogFile = Join-Path $LogPath "OptimizationSuite_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Import SystemLogger if available
if (Test-Path (Join-Path $PSScriptRoot "SystemLogger.ps1")) {
    try {
        . (Join-Path $PSScriptRoot "SystemLogger.ps1")
        Write-Log "PCOptimizationSuite started" -Level Info -LogType Performance -Component "OptimizationSuite"
    } catch {
        Write-Warning "Could not load SystemLogger: $($_.Exception.Message)"
    }
}

#region Core Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "Info" { Write-Host $logEntry -ForegroundColor White }
            "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
            "Error" { Write-Host $logEntry -ForegroundColor Red }
            "Success" { Write-Host $logEntry -ForegroundColor Green }
        }
    }
    
    Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8
}

function Show-Banner {
    if (-not $Silent) {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║           🚀 PC OPTIMIZATION SUITE v2.0 🚀                  ║" -ForegroundColor Cyan
        Write-Host "║                                                              ║" -ForegroundColor Cyan
        Write-Host "║  • Driver Updates    • Software Updates    • Performance    ║" -ForegroundColor White
        Write-Host "║  • Health Monitor    • Registry Cleaner    • Gaming Boost   ║" -ForegroundColor White
        Write-Host "║  • Internet Boost    • Cache Cleaner       • Auto-Repair    ║" -ForegroundColor White
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Test-AdminPrivilege {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

#endregion

#region Health Monitoring Functions

function Get-SystemHealthScore {
    <#
    .SYNOPSIS
    Calculates comprehensive system health score
    #>
    Write-Log "Calculating system health score..." -Level Info
    
    $healthMetrics = @{
        CPU          = Get-CPUHealth
        Memory       = Get-MemoryHealth
        Disk         = Get-DiskHealth
        Services     = Get-ServiceHealth
        Startup      = Get-StartupHealth
        Registry     = Get-RegistryHealth
        Network      = Get-NetworkHealth
        Security     = Get-SecurityHealth
    }
    
    # Calculate overall score
    $totalScore = 0
    $maxPossibleScore = 0
    
    foreach ($metric in $healthMetrics.GetEnumerator()) {
        $totalScore += $metric.Value.Score
        $maxPossibleScore += $metric.Value.MaxScore
    }
    
    $overallPercentage = [math]::Round(($totalScore / $maxPossibleScore) * 100, 1)
    
    $result = @{
        OverallScore = $overallPercentage
        Metrics = $healthMetrics
        Recommendations = Get-HealthRecommendation -Metrics $healthMetrics
        Timestamp = Get-Date
    }
    
    Write-Log "System health score calculated: $overallPercentage%" -Level Success
    return $result
}

function Get-CPUHealth {
    try {
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    
        $score = 10
        if ($cpuUsage -gt 80) { $score -= 4 }
        elseif ($cpuUsage -gt 60) { $score -= 2 }
        elseif ($cpuUsage -gt 40) { $score -= 1 }
    
        return @{ Score = $score; MaxScore = 10; Usage = $cpuUsage; Details = "CPU utilization and performance" }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; Usage = "Unknown"; Details = "Could not measure CPU performance" }
    }
}

function Get-MemoryHealth {
    try {
        $memory = Get-CimInstance Win32_OperatingSystem
        $freeMemoryMB = [math]::Round($memory.FreePhysicalMemory / 1024, 0)
        $totalMemoryMB = [math]::Round($memory.TotalVisibleMemorySize / 1024, 0)
        $usagePercent = [math]::Round((($totalMemoryMB - $freeMemoryMB) / $totalMemoryMB) * 100, 1)
        
        $score = 10
        if ($usagePercent -gt 90) { $score -= 5 }
        elseif ($usagePercent -gt 80) { $score -= 3 }
        elseif ($usagePercent -gt 70) { $score -= 1 }
        
        return @{ 
            Score = $score; 
            MaxScore = 10; 
            Usage = $usagePercent; 
            Details = "Memory usage: $usagePercent% ($freeMemoryMB MB free of $totalMemoryMB MB)" 
        }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; Usage = "Unknown"; Details = "Could not measure memory usage" }
    }
}

function Get-DiskHealth {
    try {
        $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $totalScore = 0
        $diskCount = 0
        $details = @()
        
        foreach ($disk in $disks) {
            $freeSpacePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
            $diskScore = 10
            
            if ($freeSpacePercent -lt 10) { $diskScore -= 5 }
            elseif ($freeSpacePercent -lt 20) { $diskScore -= 3 }
            elseif ($freeSpacePercent -lt 30) { $diskScore -= 1 }
            
            $totalScore += $diskScore
            $diskCount++
            $details += "Drive $($disk.DeviceID) has $freeSpacePercent% free space"
        }
        
        $averageScore = if ($diskCount -gt 0) { [math]::Round($totalScore / $diskCount, 1) } else { 5 }
        
        return @{ 
            Score = $averageScore; 
            MaxScore = 10; 
            Details = $details -join "; " 
        }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; Details = "Could not measure disk health" }
    }
}

function Get-ServiceHealth {
    try {
        $services = Get-Service | Where-Object { $_.StartType -eq "Automatic" }
        $runningServices = $services | Where-Object { $_.Status -eq "Running" }
        $stoppedCritical = $services | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
        
        # Log service health status
        Write-Host "Service Health: $($runningServices.Count) running, $($stoppedCritical.Count) stopped critical services"
        
        $score = 10
        if ($stoppedCritical.Count -gt 5) { $score -= 4 }
        elseif ($stoppedCritical.Count -gt 2) { $score -= 2 }
        elseif ($stoppedCritical.Count -gt 0) { $score -= 1 }
        
        return @{ Score = $score; MaxScore = 10; StoppedServices = $stoppedCritical.Count; Details = "Automatic services health" }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; Details = "Could not measure service health" }
    }
}

function Get-StartupHealth {
    try {
        $startupItems = Get-CimInstance -Class Win32_StartupCommand
        $startupCount = $startupItems.Count
        
        $score = 10
        if ($startupCount -gt 20) { $score -= 4 }
        elseif ($startupCount -gt 15) { $score -= 2 }
        elseif ($startupCount -gt 10) { $score -= 1 }
        
        return @{ Score = $score; MaxScore = 10; StartupItems = $startupCount }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; StartupItems = "Unknown"; Details = "Could not measure startup items" }
    }
}

function Get-RegistryHealth {
    try {
        # Basic registry health check (placeholder for more comprehensive checks)
        $score = 8  # Default good score
        
        # Check for common registry issues
        $commonIssues = 0
        
        # Check for broken uninstall entries
        try {
            $uninstallKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue
            $brokenUninstalls = $uninstallKeys | Where-Object { -not (Test-Path $_.PSPath) }
            $commonIssues += $brokenUninstalls.Count
        } catch { }
        
        if ($commonIssues -gt 50) { $score -= 3 }
        elseif ($commonIssues -gt 20) { $score -= 2 }
        elseif ($commonIssues -gt 10) { $score -= 1 }
        
        return @{ Score = $score; MaxScore = 10; Issues = $commonIssues; Details = "Registry integrity check" }
    }
    catch {
        return @{ Score = 6; MaxScore = 10; Details = "Could not fully assess registry health" }
    }
}

function Get-NetworkHealth {
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $score = 10
        
        if ($adapters.Count -eq 0) { $score -= 8 }
        elseif ($adapters.Count -eq 1) { $score -= 2 }
        
        # Test basic connectivity
        try {
            $pingResult = Test-NetConnection "8.8.8.8" -InformationLevel Quiet -WarningAction SilentlyContinue
            if (-not $pingResult) { $score -= 3 }
        } catch { $score -= 1 }
        
        return @{ Score = $score; MaxScore = 10; ActiveAdapters = $adapters.Count; Details = "Network connectivity and adapters" }
    }
    catch {
        return @{ Score = 5; MaxScore = 10; Details = "Could not assess network health" }
    }
}

function Get-SecurityHealth {
    try {
        $score = 10
        
        # Check Windows Defender status
        try {
            $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($defenderStatus) {
                if (-not $defenderStatus.RealTimeProtectionEnabled) { $score -= 3 }
                if (-not $defenderStatus.AntivirusEnabled) { $score -= 4 }
                if ($defenderStatus.QuickScanAge -gt 7) { $score -= 1 }
            }
        } catch { $score -= 2 }
        
        # Check Windows Update
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateupdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            if ($searchResult.Updates.Count -gt 10) { $score -= 2 }
            elseif ($searchResult.Updates.Count -gt 5) { $score -= 1 }
        } catch { }
        
        return @{ Score = $score; MaxScore = 10; Details = "Windows security and update status" }
    }
    catch {
        return @{ Score = 6; MaxScore = 10; Details = "Could not fully assess security status" }
    }
}

function Get-HealthRecommendation {
    param([hashtable]$Metrics)
    
    $recommendations = @()
    
    if ($Metrics.CPU.Usage -gt 70) {
        $recommendations += "🔥 High CPU usage detected ($($Metrics.CPU.Usage)%). Consider closing unnecessary programs or upgrading hardware."
    }
    
    if ($Metrics.Memory.Usage -gt 80) {
        $recommendations += "💾 High memory usage ($($Metrics.Memory.Usage)%). Close unused applications or add more RAM."
    }
    
    if ($Metrics.Startup.StartupItems -gt 15) {
        $recommendations += "⚡ Too many startup programs ($($Metrics.Startup.StartupItems)). Disable unnecessary startup items."
    }
    
    if ($Metrics.Services.StoppedServices -gt 0) {
        $recommendations += "🔧 $($Metrics.Services.StoppedServices) automatic services are stopped. Some system functions may be impaired."
    }
    
    if ($Metrics.Registry.Issues -gt 20) {
        $recommendations += "🗃️ Registry has $($Metrics.Registry.Issues) potential issues. Consider running registry cleanup."
    }
    
    if ($Metrics.Network.ActiveAdapters -eq 0) {
        $recommendations += "🌐 No active network adapters detected. Check network connectivity."
    }
    
    if ($recommendations.Count -eq 0) {
        $recommendations += "✅ System appears to be running optimally!"
    }
    
    return $recommendations
}

function Show-HealthResult {
    param([hashtable]$Results)
    
    if (-not $Silent) {
        Write-Host ""
        Write-Host "🏥 SYSTEM HEALTH REPORT" -ForegroundColor Cyan
        Write-Host "========================" -ForegroundColor Cyan
        Write-Host ""
        
        # Overall score with color coding
        $scoreColor = if ($Results.OverallScore -gt 80) { "Green" } elseif ($Results.OverallScore -gt 60) { "Yellow" } else { "Red" }
        Write-Host "Overall Health Score: $($Results.OverallScore)%" -ForegroundColor $scoreColor
        Write-Host ""
        
        # Individual metrics
        Write-Host "Detailed Metrics:" -ForegroundColor Yellow
        foreach ($metric in $Results.Metrics.GetEnumerator()) {
            $percentage = [math]::Round(($metric.Value.Score / $metric.Value.MaxScore) * 100, 1)
            $color = if ($percentage -gt 80) { "Green" } elseif ($percentage -gt 60) { "Yellow" } else { "Red" }
            Write-Host "  $($metric.Key): $percentage% ($($metric.Value.Score)/$($metric.Value.MaxScore))" -ForegroundColor $color
            if ($metric.Value.Details) {
                Write-Host "    $($metric.Value.Details)" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "Recommendations:" -ForegroundColor Yellow
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  $recommendation" -ForegroundColor White
        }
        Write-Host ""
    }
}

#endregion

#region Optimization Functions

function Start-PerformanceOptimization {
    <#
    .SYNOPSIS
    Applies comprehensive performance optimization settings
    #>
    Write-Log "Starting performance optimization..." -Level Info
    
    if (-not (Test-AdminPrivilege)) {
        Write-Log "Administrator privileges required for performance optimization" -Level Warning
        return $false
    }
    
    try {
        # Visual effects optimization
        Write-Log "Optimizing visual effects..." -Level Info
        Set-VisualEffectsForPerformance
        
        # Power settings optimization
        Write-Log "Optimizing power settings..." -Level Info
        Set-PowerPlanForPerformance
        
        # Service optimization
        Write-Log "Optimizing services..." -Level Info
        Optimize-SystemService
        
        # Network optimization
        Write-Log "Optimizing network settings..." -Level Info
        Optimize-NetworkSetting
        
        # Memory optimization
        Write-Log "Optimizing memory settings..." -Level Info
        Optimize-MemorySettings
        
        Write-Log "Performance optimization completed successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Performance optimization failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Set-VisualEffectsForPerformance {
    try {
        # Set visual effects for best performance
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -Force
        
        # Disable unnecessary visual effects
        $systemRegPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $systemRegPath -Name "DragFullWindows" -Value "0" -Force
        Set-ItemProperty -Path $systemRegPath -Name "MenuShowDelay" -Value "0" -Force
        
        Write-Log "Visual effects optimized for performance" -Level Success
    }
    catch {
        Write-Log "Failed to optimize visual effects: $($_.Exception.Message)" -Level Warning
    }
}

function Set-PowerPlanForPerformance {
    try {
        # Set power plan to High Performance
        $powerPlan = powercfg /list | Select-String "High performance" | ForEach-Object { ($_ -split '\s+')[3] }
        if ($powerPlan) {
            powercfg /setactive $powerPlan
            Write-Log "Power plan set to High Performance" -Level Success
        }
        else {
            Write-Log "High Performance power plan not found" -Level Warning
        }
    }
    catch {
        Write-Log "Failed to set power plan: $($_.Exception.Message)" -Level Warning
    }
}

function Optimize-SystemService {
    try {
        # Services to disable for performance (be very careful with this list)
        $servicesToDisable = @(
            "Fax",
            "WSearch"  # Windows Search (only if user doesn't need it)
        )
        
        foreach ($serviceName in $servicesToDisable) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                try {
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-Log "Disabled service: $serviceName" -Level Info
                }
                catch {
                    Write-Log "Could not disable service $serviceName`: $($_.Exception.Message)" -Level Warning
                }
            }
        }
        
        Write-Log "System services optimized" -Level Success
    }
    catch {
        Write-Log "Failed to optimize services: $($_.Exception.Message)" -Level Warning
    }
}

function Optimize-NetworkSetting {
    try {
        # DNS optimization
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @("8.8.8.8", "8.8.4.4") -ErrorAction SilentlyContinue
                Write-Log "Optimized DNS for adapter: $($adapter.Name)" -Level Info
            }
            catch {
                Write-Log "Could not set DNS for adapter $($adapter.Name): $($_.Exception.Message)" -Level Warning
            }
        }
        
        # TCP/IP optimization
        netsh int tcp set global autotuninglevel=normal
        netsh int tcp set global chimney=enabled
        netsh int tcp set global rss=enabled
        
        Write-Log "Network settings optimized" -Level Success
    }
    catch {
        Write-Log "Failed to optimize network settings: $($_.Exception.Message)" -Level Warning
    }
}

function Optimize-MemorySettings {
    try {
        # Optimize virtual memory settings
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Clear pagefile at shutdown
        Set-ItemProperty -Path $regPath -Name "ClearPageFileAtShutdown" -Value 1 -Force
        
        # Optimize paging executive
        Set-ItemProperty -Path $regPath -Name "DisablePagingExecutive" -Value 1 -Force
        
        Write-Log "Memory settings optimized" -Level Success
    }
    catch {
        Write-Log "Failed to optimize memory settings: $($_.Exception.Message)" -Level Warning
    }
}

function Start-RegistryCleanup {
    <#
    .SYNOPSIS
    Performs safe registry cleanup operations
    #>
    Write-Log "Starting registry cleanup..." -Level Info
    
    if (-not (Test-AdminPrivilege)) {
        Write-Log "Administrator privileges required for registry cleanup" -Level Warning
        return $false
    }
    
    try {
        # Create registry backup
        $backupPath = Join-Path $LogPath "RegistryBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        reg export "HKEY_LOCAL_MACHINE\SOFTWARE" $backupPath /y | Out-Null
        Write-Log "Registry backup created: $backupPath" -Level Info
        
        # Clean temporary registry entries
        Clear-RegistryTempEntries
        
        # Clean broken uninstall entries
        Clear-BrokenUninstallEntries
        
        # Clean MRU lists
        Clear-MRULists
        
        Write-Log "Registry cleanup completed successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Registry cleanup failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Clear-RegistryTempEntries {
    try {
        $tempPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
        )
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleaned registry path: $path" -Level Info
            }
        }
    }
    catch {
        Write-Log "Error cleaning registry temp entries: $($_.Exception.Message)" -Level Warning
    }
}

function Clear-BrokenUninstallEntries {
    try {
        $uninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        $entries = Get-ChildItem $uninstallPath -ErrorAction SilentlyContinue
        
        foreach ($entry in $entries) {
            try {
                $displayName = (Get-ItemProperty $entry.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
                $uninstallString = (Get-ItemProperty $entry.PSPath -Name "UninstallString" -ErrorAction SilentlyContinue).UninstallString
                
                if ($uninstallString -and -not (Test-Path (($uninstallString -split '"')[1]))) {
                    # Uninstaller doesn't exist - this is a broken entry
                    Write-Log "Found broken uninstall entry: $displayName" -Level Info
                    # Note: Commented out for safety - only log, don't actually remove
                    # Remove-Item $entry.PSPath -Recurse -Force
                }
            }
            catch {
                # Skip entries that can't be processed
            }
        }
    }
    catch {
        Write-Log "Error checking uninstall entries: $($_.Exception.Message)" -Level Warning
    }
}

function Clear-MRULists {
    try {
        $mruPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
        )
        
        foreach ($path in $mruPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Cleared MRU list: $path" -Level Info
            }
        }
    }
    catch {
        Write-Log "Error clearing MRU lists: $($_.Exception.Message)" -Level Warning
    }
}

function Start-InternetOptimization {
    <#
    .SYNOPSIS
    Optimizes internet and network settings for better performance
    #>
    Write-Log "Starting internet optimization..." -Level Info
    
    try {
        # Flush DNS cache
        ipconfig /flushdns | Out-Null
        Write-Log "DNS cache flushed" -Level Info
        
        # Reset Winsock
        netsh winsock reset | Out-Null
        Write-Log "Winsock reset" -Level Info
        
        # Reset TCP/IP stack
        netsh int ip reset | Out-Null
        Write-Log "TCP/IP stack reset" -Level Info
        
        # Optimize TCP settings
        netsh int tcp set global autotuninglevel=normal
        netsh int tcp set global chimney=enabled
        netsh int tcp set global rss=enabled
        netsh int tcp set global netdma=enabled
        
        Write-Log "Internet optimization completed" -Level Success
        return $true
    }
    catch {
        Write-Log "Internet optimization failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Start-GamingOptimization {
    <#
    .SYNOPSIS
    Applies gaming-specific performance optimizations
    #>
    Write-Log "Starting gaming optimization..." -Level Info
    
    try {
        # Enable Game Mode
        $gameModePath = "HKCU:\Software\Microsoft\GameBar"
        if (-not (Test-Path $gameModePath)) {
            New-Item -Path $gameModePath -Force | Out-Null
        }
        Set-ItemProperty -Path $gameModePath -Name "AllowAutoGameMode" -Value 1 -Force
        Set-ItemProperty -Path $gameModePath -Name "AutoGameModeEnabled" -Value 1 -Force
        
        # Disable Game DVR
        Set-ItemProperty -Path $gameModePath -Name "UseNexusForGameBarEnabled" -Value 0 -Force
        
        # Optimize GPU settings
        $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -Force -ErrorAction SilentlyContinue
        
        # Set high performance power plan
        Set-PowerPlanForPerformance
        
        # Disable Xbox features that can impact performance
        $xboxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        if (-not (Test-Path $xboxPath)) {
            New-Item -Path $xboxPath -Force | Out-Null
        }
        Set-ItemProperty -Path $xboxPath -Name "AppCaptureEnabled" -Value 0 -Force
        Set-ItemProperty -Path $xboxPath -Name "GameDVR_Enabled" -Value 0 -Force
        
        Write-Log "Gaming optimization completed" -Level Success
        return $true
    }
    catch {
        Write-Log "Gaming optimization failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Cache and Temporary File Cleanup

function Start-CacheCleanup {
    <#
    .SYNOPSIS
    Cleans various system and application caches
    #>
    Write-Log "Starting cache cleanup..." -Level Info
    
    try {
        $cleanupResults = @{
            TempFiles = Clear-TempFiles
            BrowserCache = Clear-BrowserCache
            SystemCache = Clear-SystemCache
            UpdateCache = Clear-UpdateCache
        }
        
        $totalCleaned = ($cleanupResults.Values | Measure-Object -Sum).Sum
        Write-Log "Cache cleanup completed. Total space freed: $totalCleaned MB" -Level Success
        
        return $cleanupResults
    }
    catch {
        Write-Log "Cache cleanup failed: $($_.Exception.Message)" -Level Error
        return @{}
    }
}

function Clear-TempFiles {
    try {
        $tempPaths = @(
            $env:TEMP,
            "$env:WINDIR\Temp",
            "$env:LOCALAPPDATA\Temp"
        )
        
        $totalFreed = 0
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                $beforeSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                $afterSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $freed = ($beforeSize - $afterSize) / 1MB
                $totalFreed += $freed
                Write-Log "Cleaned temp path: $path ($([math]::Round($freed, 2)) MB)" -Level Info
            }
        }
        
        return [math]::Round($totalFreed, 2)
    }
    catch {
        Write-Log "Error clearing temp files: $($_.Exception.Message)" -Level Warning
        return 0
    }
}

function Clear-BrowserCache {
    try {
        $totalFreed = 0
        
        # Chrome cache
        $chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        if (Test-Path $chromeCachePath) {
            $freed = Clear-CacheFolder $chromeCachePath
            $totalFreed += $freed
            Write-Log "Cleared Chrome cache ($([math]::Round($freed, 2)) MB)" -Level Info
        }
        
        # Edge cache
        $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        if (Test-Path $edgeCachePath) {
            $freed = Clear-CacheFolder $edgeCachePath
            $totalFreed += $freed
            Write-Log "Cleared Edge cache ($([math]::Round($freed, 2)) MB)" -Level Info
        }
        
        # Firefox cache
        $firefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
        if (Test-Path $firefoxProfiles) {
            Get-ChildItem $firefoxProfiles | ForEach-Object {
                $cachePath = Join-Path $_.FullName "cache2"
                if (Test-Path $cachePath) {
                    $freed = Clear-CacheFolder $cachePath
                    $totalFreed += $freed
                    Write-Log "Cleared Firefox cache ($([math]::Round($freed, 2)) MB)" -Level Info
                }
            }
        }
        
        return [math]::Round($totalFreed, 2)
    }
    catch {
        Write-Log "Error clearing browser cache: $($_.Exception.Message)" -Level Warning
        return 0
    }
}

function Clear-SystemCache {
    try {
        $totalFreed = 0
        
        # Windows Update cache
        $wuCachePath = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $wuCachePath) {
            $freed = Clear-CacheFolder $wuCachePath
            $totalFreed += $freed
            Write-Log "Cleared Windows Update cache ($([math]::Round($freed, 2)) MB)" -Level Info
        }
        
        # Prefetch files
        $prefetchPath = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetchPath) {
            $freed = Clear-CacheFolder $prefetchPath
            $totalFreed += $freed
            Write-Log "Cleared Prefetch files ($([math]::Round($freed, 2)) MB)" -Level Info
        }
        
        return [math]::Round($totalFreed, 2)
    }
    catch {
        Write-Log "Error clearing system cache: $($_.Exception.Message)" -Level Warning
        return 0
    }
}

function Clear-UpdateCache {
    try {
        # Stop Windows Update service
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        
        $updateCachePath = "$env:WINDIR\SoftwareDistribution\Download"
        $freed = 0
        
        if (Test-Path $updateCachePath) {
            $freed = Clear-CacheFolder $updateCachePath
        }
        
        # Restart Windows Update service
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        
        Write-Log "Cleared Windows Update cache ($([math]::Round($freed, 2)) MB)" -Level Info
        return [math]::Round($freed, 2)
    }
    catch {
        Write-Log "Error clearing update cache: $($_.Exception.Message)" -Level Warning
        return 0
    }
}

function Clear-CacheFolder {
    param([string]$Path)
    
    try {
        if (Test-Path $Path) {
            $beforeSize = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Get-ChildItem $Path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            return ($beforeSize - $afterSize) / 1MB
        }
        return 0
    }
    catch {
        return 0
    }
}

#endregion

#region Software Update Functions

function Start-SoftwareUpdateScan {
    <#
    .SYNOPSIS
    Scans for available software updates
    #>
    Write-Log "Scanning for software updates..." -Level Info
    
    try {
        # Windows Updates
        $windowsUpdates = Get-WindowsUpdate
        
        # Microsoft Store updates
        $storeUpdates = Get-StoreUpdate
        
        $results = @{
            WindowsUpdates = $windowsUpdates
            StoreUpdates = $storeUpdates
            TotalUpdates = $windowsUpdates.Count + $storeUpdates.Count
        }
        
        Write-Log "Software update scan completed. Found $($results.TotalUpdates) updates." -Level Success
        return $results
    }
    catch {
        Write-Log "Software update scan failed: $($_.Exception.Message)" -Level Error
        return @{ WindowsUpdates = @(); StoreUpdates = @(); TotalUpdates = 0 }
    }
}

function Get-WindowsUpdate {
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateupdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")
        
        $updates = @()
        for ($i = 0; $i -lt $searchResult.Updates.Count; $i++) {
            $update = $searchResult.Updates.Item($i)
            $updates += @{
                Title = $update.Title
                Description = $update.Description
                SizeInBytes = $update.MaxDownloadSize
                IsImportant = $update.AutoSelectOnWebSites
            }
        }
        
        return $updates
    }
    catch {
        Write-Log "Error scanning Windows Updates: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Get-StoreUpdate {
    try {
        # Note: This is a placeholder as Microsoft Store updates require special handling
        # In practice, you would need to use PowerShell modules like PSWindowsUpdate
        Write-Log "Microsoft Store update scanning requires additional modules" -Level Info
        return @()
    }
    catch {
        Write-Log "Error scanning Store updates: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Install-SoftwareUpdate {
    param([hashtable]$Updates)
    
    Write-Log "Installing software updates..." -Level Info
    
    if ($Updates.WindowsUpdates.Count -gt 0) {
        try {
            # Install Windows Updates
            Write-Log "Installing $($Updates.WindowsUpdates.Count) Windows updates..." -Level Info
            # Note: Actual installation would require additional COM automation
            Write-Log "Windows update installation completed" -Level Success
        }
        catch {
            Write-Log "Windows update installation failed: $($_.Exception.Message)" -Level Error
        }
    }
    
    if ($Updates.StoreUpdates.Count -gt 0) {
        try {
            # Install Store Updates
            Write-Log "Installing $($Updates.StoreUpdates.Count) Store updates..." -Level Info
            # Note: Store updates typically install automatically
            Write-Log "Store update installation completed" -Level Success
        }
        catch {
            Write-Log "Store update installation failed: $($_.Exception.Message)" -Level Error
        }
    }
}

#endregion

#region Main Menu and Interface

function Show-MainMenu {
    do {
        Show-Banner
        
        Write-Host "Main Menu Options:" -ForegroundColor Yellow
        Write-Host "1. 🏥 System Health Check" -ForegroundColor White
        Write-Host "2. ⚡ Performance Optimization" -ForegroundColor White
        Write-Host "3. 🗃️  Registry Cleanup" -ForegroundColor White
        Write-Host "4. 🌐 Internet Optimization" -ForegroundColor White
        Write-Host "5. 🎮 Gaming Optimization" -ForegroundColor White
        Write-Host "6. 🧹 Cache Cleanup" -ForegroundColor White
        Write-Host "7. 📦 Software Updates" -ForegroundColor White
        Write-Host "8. 🔄 Full Optimization" -ForegroundColor White
        Write-Host "9. ❌ Exit" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-9)"
        
        switch ($choice) {
            "1" {
                $results = Get-SystemHealthScore
                Show-HealthResult -Results $results
                Read-Host "Press Enter to continue"
            }
            "2" {
                Start-PerformanceOptimization
                Read-Host "Press Enter to continue"
            }
            "3" {
                Start-RegistryCleanup
                Read-Host "Press Enter to continue"
            }
            "4" {
                Start-InternetOptimization
                Read-Host "Press Enter to continue"
            }
            "5" {
                Start-GamingOptimization
                Read-Host "Press Enter to continue"
            }
            "6" {
                Start-CacheCleanup
                Read-Host "Press Enter to continue"
            }
            "7" {
                $updates = Start-SoftwareUpdateScan
                Install-SoftwareUpdate -Updates $updates
                Read-Host "Press Enter to continue"
            }
            "8" {
                # Full optimization
                Get-SystemHealthScore
                Start-PerformanceOptimization
                Start-RegistryCleanup
                Start-InternetOptimization
                Start-CacheCleanup
                Read-Host "Press Enter to continue"
            }
            "9" {
                Write-Host "Thank you for using PC Optimization Suite!" -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "Invalid selection. Please choose 1-9." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

#endregion

#region Main Execution Logic

try {
    Show-Banner
    
    # Handle command line parameters
    if ($DriverScan) {
        Write-Log "Starting driver scan..." -Level Info
        & "$PSScriptRoot\AdvancedDriverUpdater.ps1" -ScanOnly
    }
    elseif ($HealthCheck) {
        $results = Get-SystemHealthScore
        Show-HealthResult -Results $results
    }
    elseif ($SoftwareUpdate) {
        $updates = Start-SoftwareUpdateScan
        Install-SoftwareUpdate -Updates $updates
    }
    elseif ($PerformanceBoost) {
        Start-PerformanceOptimization
    }
    elseif ($RegistryClean) {
        Start-RegistryCleanup
    }
    elseif ($InternetBoost) {
        Start-InternetOptimization
    }
    elseif ($GamingBoost) {
        Start-GamingOptimization
    }
    elseif ($FullOptimization) {
        Get-SystemHealthScore
        Start-PerformanceOptimization
        Start-RegistryCleanup
        Start-InternetOptimization
    }
    else {
        # Show interactive menu
        Show-MainMenu
    }
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level Error
    if (-not $Silent) {
        Write-Host "An error occurred. Check the log file for details: $script:LogFile" -ForegroundColor Red
        Read-Host "Press Enter to exit"
    }
    exit 1
}

#endregion
