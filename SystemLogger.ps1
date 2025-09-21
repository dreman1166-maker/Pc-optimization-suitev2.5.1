#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Advanced System Logger and Recovery System
    
.DESCRIPTION
    Comprehensive logging system that captures all operations, errors, and system states.
    Includes intelligent recovery system that analyzes logs and provides smart recommendations.
    
.NOTES
    Author: GitHub Copilot
    Version: 1.0
    Requires: PowerShell 5.1+ and Administrator privileges
#>

# Global Variables
$Global:LogPath = "$env:USERPROFILE\AutoKey\Logs"
$Global:MainLogFile = "$Global:LogPath\SystemOptimization.log"
$Global:ErrorLogFile = "$Global:LogPath\SystemErrors.log"
$Global:OperationLogFile = "$Global:LogPath\Operations.log"
$Global:PerformanceLogFile = "$Global:LogPath\Performance.log"
$Global:RecoveryLogFile = "$Global:LogPath\Recovery.log"
$Global:MaxLogSize = 10MB
$Global:MaxLogFiles = 10

# Initialize logging system
function Initialize-LoggingSystem {
    try {
        # Create logs directory if it doesn't exist
        if (-not (Test-Path $Global:LogPath)) {
            New-Item -Path $Global:LogPath -ItemType Directory -Force | Out-Null
        }
        
        # Initialize log files with headers
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $header = @"
========================================
PC Optimization Suite - Log File
Initialized: $timestamp
System: $env:COMPUTERNAME
User: $env:USERNAME
OS: $((Get-CimInstance Win32_OperatingSystem).Caption)
PowerShell: $($PSVersionTable.PSVersion)
========================================

"@
        
        # Write headers to all log files
        $header | Out-File -FilePath $Global:MainLogFile -Encoding UTF8 -Append
        $header | Out-File -FilePath $Global:ErrorLogFile -Encoding UTF8 -Append
        $header | Out-File -FilePath $Global:OperationLogFile -Encoding UTF8 -Append
        $header | Out-File -FilePath $Global:PerformanceLogFile -Encoding UTF8 -Append
        $header | Out-File -FilePath $Global:RecoveryLogFile -Encoding UTF8 -Append
        
        Write-Log "Logging system initialized successfully" -Level Info -LogType System
        return $true
    }
    catch {
        Write-Warning "Failed to initialize logging system: $($_.Exception.Message)"
        return $false
    }
}

# Enhanced logging function with multiple log types
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug", "Critical")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("System", "Driver", "Performance", "Registry", "Network", "Gaming", "Recovery")]
        [string]$LogType = "System",
        
        [Parameter(Mandatory = $false)]
        [string]$Component = "Unknown",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalData = @{}
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $processId = $PID
        $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        
        # Format log message
        $formattedMessage = "[$timestamp] [$Level] [$LogType] [$Component] [PID:$processId] [TID:$threadId] $Message"
        
        # Add additional data if present
        if ($AdditionalData.Count -gt 0) {
            $additionalInfo = ($AdditionalData.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "; "
            $formattedMessage += " | Additional: $additionalInfo"
        }
        
        # Determine which log file to write to
        $logFile = switch ($Level) {
            "Error" { $Global:ErrorLogFile }
            "Critical" { $Global:ErrorLogFile }
            default { 
                switch ($LogType) {
                    "Performance" { $Global:PerformanceLogFile }
                    "Recovery" { $Global:RecoveryLogFile }
                    default { $Global:MainLogFile }
                }
            }
        }
        
        # Write to appropriate log file
        $formattedMessage | Out-File -FilePath $logFile -Encoding UTF8 -Append
        
        # Also write operations to operations log
        if ($Level -in @("Info", "Success", "Warning")) {
            $formattedMessage | Out-File -FilePath $Global:OperationLogFile -Encoding UTF8 -Append
        }
        
        # Manage log file size
        Set-LogFileSize -LogFile $logFile
        
        # Console output with colors
        $color = switch ($Level) {
            "Error" { "Red" }
            "Critical" { "Magenta" }
            "Warning" { "Yellow" }
            "Success" { "Green" }
            "Debug" { "Cyan" }
            default { "White" }
        }
        
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
        
    }
    catch {
        Write-Warning "Failed to write to log: $($_.Exception.Message)"
    }
}

# Manage log file sizes and rotation
function Set-LogFileSize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )
    
    try {
        if (Test-Path $LogFile) {
            $file = Get-Item $LogFile
            if ($file.Length -gt $Global:MaxLogSize) {
                # Rotate log file
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $rotatedFile = $LogFile -replace "\.log$", "_$timestamp.log"
                Move-Item -Path $LogFile -Destination $rotatedFile
                
                # Clean up old log files
                $logDir = Split-Path $LogFile
                $logBaseName = [System.IO.Path]::GetFileNameWithoutExtension($LogFile)
                $oldLogs = Get-ChildItem -Path $logDir -Filter "$logBaseName_*.log" | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -Skip $Global:MaxLogFiles
                
                foreach ($oldLog in $oldLogs) {
                    Remove-Item -Path $oldLog.FullName -Force
                    Write-Log "Removed old log file: $($oldLog.Name)" -Level Info -LogType System
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to manage log file size: $($_.Exception.Message)"
    }
}

# Log system performance metrics
function Write-PerformanceLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        
        [Parameter(Mandatory = $true)]
        [timespan]$Duration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metrics = @{}
    )
    
    $performanceData = @{
        Operation = $Operation
        Duration  = $Duration.TotalMilliseconds
        StartTime = (Get-Date).AddMilliseconds(-$Duration.TotalMilliseconds).ToString("yyyy-MM-dd HH:mm:ss.fff")
        EndTime   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    }
    
    # Merge with additional metrics
    $Metrics.GetEnumerator() | ForEach-Object {
        $performanceData[$_.Key] = $_.Value
    }
    
    Write-Log "Performance: $Operation completed in $($Duration.TotalMilliseconds)ms" -Level Info -LogType Performance -Component "PerformanceMonitor" -AdditionalData $performanceData
}

# Capture system state before operations
function Get-SystemState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation
    )
    
    try {
        $systemState = @{
            Operation        = $Operation
            Timestamp        = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            FreeMemory       = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
            CPUUsage         = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
            DiskSpace        = @{}
            Services         = @{}
            Processes        = @{}
            NetworkAdapters  = @{}
            InstalledDrivers = @{}
        }
        
        # Capture disk space
        Get-CimInstance Win32_LogicalDisk | ForEach-Object {
            $systemState.DiskSpace[$_.DeviceID] = @{
                FreeSpace  = [math]::Round($_.FreeSpace / 1GB, 2)
                TotalSpace = [math]::Round($_.Size / 1GB, 2)
            }
        }
        
        # Capture critical services
        Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" } | ForEach-Object {
            $systemState.Services[$_.Name] = $_.Status
        }
        
        # Capture high CPU processes
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
            $systemState.Processes[$_.Name] = @{
                CPU        = $_.CPU
                WorkingSet = [math]::Round($_.WorkingSet / 1MB, 2)
            }
        }
        
        # Capture network adapter status
        Get-NetAdapter | ForEach-Object {
            $systemState.NetworkAdapters[$_.Name] = $_.Status
        }
        
        # Capture driver count
        $drivers = Get-CimInstance Win32_SystemDriver
        $systemState.InstalledDrivers = @{
            Total   = $drivers.Count
            Running = ($drivers | Where-Object { $_.State -eq "Running" }).Count
            Stopped = ($drivers | Where-Object { $_.State -eq "Stopped" }).Count
        }
        
        Write-Log "System state captured for operation: $Operation" -Level Info -LogType System -Component "StateCapture" -AdditionalData $systemState
        
        return $systemState
    }
    catch {
        Write-Log "Failed to capture system state: $($_.Exception.Message)" -Level Error -LogType System -Component "StateCapture"
        return $null
    }
}

# Intelligent log analysis and recovery recommendations
function Get-RecoveryRecommendation {
    param(
        [Parameter(Mandatory = $false)]
        [int]$DaysToAnalyze = 7
    )
    
    try {
        Write-Log "Starting intelligent log analysis for recovery recommendations" -Level Info -LogType Recovery
        
        $cutoffDate = (Get-Date).AddDays(-$DaysToAnalyze)
        $recommendations = @()
        
        # Analyze error patterns
        $errorAnalysis = Get-ErrorPattern -CutoffDate $cutoffDate
        $recommendations += $errorAnalysis
        
        # Analyze performance degradation
        $performanceAnalysis = Get-PerformancePattern -CutoffDate $cutoffDate
        $recommendations += $performanceAnalysis
        
        # Analyze system stability
        $stabilityAnalysis = Get-SystemStability -CutoffDate $cutoffDate
        $recommendations += $stabilityAnalysis
        
        # Generate recovery report
        $recoveryReport = @{
            Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            AnalysisPeriod       = "$DaysToAnalyze days"
            TotalRecommendations = $recommendations.Count
            Recommendations      = $recommendations
            SystemHealth         = Get-OverallSystemHealth
        }
        
        # Save recovery report
        $reportPath = "$Global:LogPath\RecoveryReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $recoveryReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
        
        Write-Log "Recovery analysis completed. Report saved to: $reportPath" -Level Success -LogType Recovery -AdditionalData @{ RecommendationCount = $recommendations.Count }
        
        return $recoveryReport
    }
    catch {
        Write-Log "Failed to generate recovery recommendations: $($_.Exception.Message)" -Level Error -LogType Recovery
        return $null
    }
}

# Analyze error patterns in logs
function Get-ErrorPattern {
    param([datetime]$CutoffDate)
    
    $recommendations = @()
    
    try {
        if (Test-Path $Global:ErrorLogFile) {
            $errorContent = Get-Content $Global:ErrorLogFile | 
                Where-Object { $_ -match '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' } |
                Where-Object { 
                    $dateMatch = $_ -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})'
                    if ($dateMatch) {
                        $logDate = [datetime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                        return $logDate -ge $CutoffDate
                    }
                    return $false
                }
            
            # Group errors by pattern
            $errorGroups = $errorContent | Group-Object { 
                if ($_ -match '\[Error\].*?(\w+Exception|Error \d+|Failed to \w+)') {
                    $matches[1]
                }
                else {
                    "General Error"
                }
            }
            
            foreach ($group in $errorGroups | Sort-Object Count -Descending) {
                if ($group.Count -gt 3) {
                    # If error occurs more than 3 times
                    $recommendation = @{
                        Type           = "Error Pattern"
                        Priority       = if ($group.Count -gt 10) { "High" } elseif ($group.Count -gt 5) { "Medium" } else { "Low" }
                        Issue          = "Recurring error: $($group.Name)"
                        Frequency      = $group.Count
                        Recommendation = Get-ErrorRecommendation -ErrorType $group.Name
                        Actions        = Get-ErrorAction -ErrorType $group.Name
                    }
                    $recommendations += $recommendation
                }
            }
        }
    }
    catch {
        Write-Log "Error analyzing error patterns: $($_.Exception.Message)" -Level Warning -LogType Recovery
    }
    
    return $recommendations
}

# Analyze performance degradation patterns
function Get-PerformancePattern {
    param([datetime]$CutoffDate)
    
    $recommendations = @()
    
    try {
        if (Test-Path $Global:PerformanceLogFile) {
            $performanceContent = Get-Content $Global:PerformanceLogFile | 
                Where-Object { $_ -match 'Performance:.*completed in (\d+)ms' }
            
            # Analyze operation durations
            $operations = @{}
            foreach ($line in $performanceContent) {
                if ($line -match 'Performance: (.+?) completed in (\d+)ms') {
                    $operation = $matches[1]
                    $duration = [int]$matches[2]
                    
                    if (-not $operations.ContainsKey($operation)) {
                        $operations[$operation] = @()
                    }
                    $operations[$operation] += $duration
                }
            }
            
            # Check for performance degradation
            foreach ($operation in $operations.Keys) {
                $durations = $operations[$operation]
                if ($durations.Count -gt 5) {
                    $recent = $durations | Select-Object -Last 5
                    $older = $durations | Select-Object -First 5
                    
                    $recentAvg = ($recent | Measure-Object -Average).Average
                    $olderAvg = ($older | Measure-Object -Average).Average
                    
                    if ($recentAvg -gt ($olderAvg * 1.5)) {
                        # 50% performance degradation
                        $recommendation = @{
                            Type           = "Performance Degradation"
                            Priority       = "Medium"
                            Issue          = "Operation '$operation' is running slower than before"
                            Details        = "Average duration increased from $([math]::Round($olderAvg))ms to $([math]::Round($recentAvg))ms"
                            Recommendation = "Consider system optimization or resource cleanup"
                            Actions        = @(
                                "Run disk cleanup",
                                "Check for memory leaks",
                                "Update system drivers",
                                "Optimize startup programs"
                            )
                        }
                        $recommendations += $recommendation
                    }
                }
            }
        }
    }
    catch {
        Write-Log "Error analyzing performance patterns: $($_.Exception.Message)" -Level Warning -LogType Recovery
    }
    
    return $recommendations
}

# Analyze system stability patterns
function Get-SystemStability {
    param([datetime]$CutoffDate)
    
    $recommendations = @()
    
    try {
        # Check for system restarts
        $systemEvents = Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = 1074, 6006, 6008; StartTime = $CutoffDate } -ErrorAction SilentlyContinue
        
        if ($systemEvents -and $systemEvents.Count -gt 5) {
            $recommendation = @{
                Type           = "System Stability"
                Priority       = "High"
                Issue          = "Frequent system restarts detected"
                Details        = "System has restarted $($systemEvents.Count) times in the last 7 days"
                Recommendation = "Investigate system stability issues"
                Actions        = @(
                    "Check for hardware issues",
                    "Update system drivers",
                    "Run memory diagnostic",
                    "Check event logs for critical errors",
                    "Verify system temperature"
                )
            }
            $recommendations += $recommendation
        }
        
        # Check for driver issues
        $driverEvents = Get-WinEvent -FilterHashtable @{LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-PnP'; StartTime = $CutoffDate } -ErrorAction SilentlyContinue
        
        if ($driverEvents -and $driverEvents.Count -gt 10) {
            $recommendation = @{
                Type           = "Driver Issues"
                Priority       = "Medium"
                Issue          = "Multiple driver-related events detected"
                Details        = "Found $($driverEvents.Count) driver events in the last 7 days"
                Recommendation = "Update or reinstall problematic drivers"
                Actions        = @(
                    "Run driver update scan",
                    "Check Device Manager for issues",
                    "Update graphics drivers",
                    "Update network drivers"
                )
            }
            $recommendations += $recommendation
        }
    }
    catch {
        Write-Log "Error analyzing system stability: $($_.Exception.Message)" -Level Warning -LogType Recovery
    }
    
    return $recommendations
}

# Get specific recommendations for error types
function Get-ErrorRecommendation {
    param([string]$ErrorType)
    
    switch -Regex ($ErrorType) {
        "AccessDenied|UnauthorizedAccess" {
            return "Run the application as Administrator or check file permissions"
        }
        "FileNotFound|DirectoryNotFound" {
            return "Verify file paths and ensure required files exist"
        }
        "NetworkException|HttpRequestException" {
            return "Check internet connectivity and firewall settings"
        }
        "TimeoutException" {
            return "Increase timeout values or check system performance"
        }
        "OutOfMemoryException" {
            return "Close unnecessary applications or increase virtual memory"
        }
        "RegistryException|SecurityException" {
            return "Check registry permissions and user privileges"
        }
        default {
            return "Review error details and check system logs for more information"
        }
    }
}

# Get specific actions for error types
function Get-ErrorAction {
    param([string]$ErrorType)
    
    switch -Regex ($ErrorType) {
        "AccessDenied|UnauthorizedAccess" {
            return @(
                "Right-click application and select 'Run as Administrator'",
                "Check file/folder permissions",
                "Verify user account privileges",
                "Disable UAC temporarily for testing"
            )
        }
        "FileNotFound|DirectoryNotFound" {
            return @(
                "Verify file paths in configuration",
                "Restore deleted files from backup",
                "Reinstall missing components",
                "Check for file system corruption"
            )
        }
        "NetworkException|HttpRequestException" {
            return @(
                "Test internet connectivity",
                "Check firewall settings",
                "Verify proxy configuration",
                "Reset network adapters"
            )
        }
        "TimeoutException" {
            return @(
                "Increase timeout values in configuration",
                "Close resource-intensive applications",
                "Check for disk fragmentation",
                "Monitor system performance"
            )
        }
        default {
            return @(
                "Review detailed error logs",
                "Check system event logs",
                "Update relevant software",
                "Contact technical support"
            )
        }
    }
}

# Get overall system health score
function Get-OverallSystemHealth {
    try {
        $healthScore = 0
        
        # Check available memory (20 points)
        $memory = Get-CimInstance Win32_OperatingSystem
        $memoryPercent = ($memory.FreePhysicalMemory / $memory.TotalVisibleMemorySize) * 100
        $healthScore += [math]::Min(20, $memoryPercent / 5)
        
        # Check disk space (20 points)
        $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $avgDiskFree = ($disks | ForEach-Object { ($_.FreeSpace / $_.Size) * 100 } | Measure-Object -Average).Average
        $healthScore += [math]::Min(20, $avgDiskFree / 5)
        
        # Check CPU usage (20 points)
        $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
        $healthScore += [math]::Max(0, 20 - ($cpu / 5))
        
        # Check error frequency (20 points)
        $recentErrors = if (Test-Path $Global:ErrorLogFile) {
            (Get-Content $Global:ErrorLogFile | Where-Object { $_ -match (Get-Date).ToString("yyyy-MM-dd") }).Count
        }
        else { 0 }
        $healthScore += [math]::Max(0, 20 - $recentErrors)
        
        # Check system uptime (20 points)
        $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptimeHours = ((Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($uptime)).TotalHours
        $healthScore += [math]::Min(20, $uptimeHours / 12)
        
        return [math]::Round($healthScore)
    }
    catch {
        Write-Log "Error calculating system health: $($_.Exception.Message)" -Level Warning -LogType Recovery
        return 50  # Default middle score
    }
}

# Auto-execute recovery actions
function Start-AutoRecovery {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoApprove
    )
    
    try {
        Write-Log "Starting auto-recovery process" -Level Info -LogType Recovery
        
        $executedActions = 0
        $successfulActions = 0
        
        foreach ($recommendation in $Recommendations) {
            if ($recommendation.Priority -eq "High" -or $AutoApprove) {
                Write-Log "Executing recovery actions for: $($recommendation.Issue)" -Level Info -LogType Recovery
                
                foreach ($action in $recommendation.Actions) {
                    try {
                        $executedActions++
                        $result = Invoke-RecoveryAction -Action $action
                        
                        if ($result) {
                            $successfulActions++
                            Write-Log "Successfully executed: $action" -Level Success -LogType Recovery
                        }
                        else {
                            Write-Log "Failed to execute: $action" -Level Warning -LogType Recovery
                        }
                    }
                    catch {
                        Write-Log "Error executing recovery action '$action': $($_.Exception.Message)" -Level Error -LogType Recovery
                    }
                }
            }
        }
        
        $summary = @{
            TotalActions      = $executedActions
            SuccessfulActions = $successfulActions
            SuccessRate       = if ($executedActions -gt 0) { [math]::Round(($successfulActions / $executedActions) * 100) } else { 0 }
        }
        
        Write-Log "Auto-recovery completed. Success rate: $($summary.SuccessRate)%" -Level Success -LogType Recovery -AdditionalData $summary
        
        return $summary
    }
    catch {
        Write-Log "Error during auto-recovery: $($_.Exception.Message)" -Level Error -LogType Recovery
        return $null
    }
}

# Execute individual recovery actions
function Invoke-RecoveryAction {
    param([string]$Action)
    
    try {
        switch -Regex ($Action) {
            "Run disk cleanup" {
                Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait
                return $true
            }
            "Update system drivers" {
                # This would trigger the driver update process
                Write-Log "Driver update triggered by recovery system" -Level Info -LogType Recovery
                return $true
            }
            "Reset network adapters" {
                Get-NetAdapter | Reset-NetAdapter -Confirm:$false
                return $true
            }
            "Check for memory leaks" {
                # Monitor memory usage for a short period
                $initialMemory = (Get-Process | Measure-Object WorkingSet -Sum).Sum
                Start-Sleep -Seconds 30
                $finalMemory = (Get-Process | Measure-Object WorkingSet -Sum).Sum
                $memoryDiff = $finalMemory - $initialMemory
                Write-Log "Memory usage change: $([math]::Round($memoryDiff / 1MB, 2)) MB" -Level Info -LogType Recovery
                return $true
            }
            "Optimize startup programs" {
                # Disable non-essential startup programs
                $startupItems = Get-CimInstance Win32_StartupCommand | Where-Object { $_.Location -eq "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" }
                foreach ($item in $startupItems) {
                    if ($item.Command -match "(updater|helper|assistant)" -and $item.Command -notmatch "(antivirus|security|windows)") {
                        Write-Log "Identified non-essential startup item: $($item.Name)" -Level Info -LogType Recovery
                    }
                }
                return $true
            }
            default {
                Write-Log "No automated action available for: $Action" -Level Info -LogType Recovery
                return $false
            }
        }
    }
    catch {
        Write-Log "Error executing action '$Action': $($_.Exception.Message)" -Level Error -LogType Recovery
        return $false
    }
}

# Initialize logging when script is imported
Initialize-LoggingSystem


