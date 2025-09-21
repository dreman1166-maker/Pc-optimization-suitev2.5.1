#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    GUI Performance Optimizations for PC Optimization Suite
    
.DESCRIPTION
    This module provides performance optimizations for the GUI including:
    - Background data collection
    - Intelligent caching
    - Async UI updates
    - Optimized refresh cycles
#>

# Performance optimization variables
$script:SystemDataCache = @{}
$script:CacheExpiration = @{}
$script:BackgroundJobs = @{}
$script:LastUIUpdate = Get-Date
$script:DataCollectionTimer = $null
$script:UIUpdateTimer = $null

# Cache duration settings (in seconds)
$script:CacheDurations = @{
    SystemOverview     = 30      # 30 seconds
    DriverHealth       = 60      # 1 minute
    PerformanceScore   = 300     # 5 minutes
    SystemInfo         = 3600    # 1 hour (rarely changes)
}

function Initialize-PerformanceOptimizations {
    <#
    .SYNOPSIS
        Initialize performance optimization system for GUI
    #>
    
    Write-Host "🚀 Initializing GUI performance optimizations..." -ForegroundColor Green
    
    # Initialize cache
    $script:SystemDataCache = @{}
    $script:CacheExpiration = @{}
    
    # Start background data collection
    Start-BackgroundDataCollection
    
    # Start optimized UI update timer
    Start-OptimizedUIUpdates
    
    Write-Host "✅ Performance optimizations initialized" -ForegroundColor Green
}

function Stop-PerformanceOptimizations {
    <#
    .SYNOPSIS
        Clean up performance optimization resources
    #>
    
    # Stop timers
    if ($script:DataCollectionTimer) {
        $script:DataCollectionTimer.Stop()
        $script:DataCollectionTimer.Dispose()
        $script:DataCollectionTimer = $null
    }
    
    if ($script:UIUpdateTimer) {
        $script:UIUpdateTimer.Stop()
        $script:UIUpdateTimer.Dispose()
        $script:UIUpdateTimer = $null
    }
    
    # Clean up background jobs
    foreach ($job in $script:BackgroundJobs.Values) {
        if ($job -and $job.State -eq 'Running') {
            Stop-Job $job -Force
            Remove-Job $job -Force
        }
    }
    $script:BackgroundJobs.Clear()
    
    Write-Host "🔄 Performance optimizations stopped" -ForegroundColor Yellow
}

function Get-CachedData {
    <#
    .SYNOPSIS
        Get cached data if available and not expired
    #>
    param(
        [string]$DataType
    )
    
    $currentTime = Get-Date
    
    # Check if data exists and is not expired
    if ($script:SystemDataCache.ContainsKey($DataType) -and 
        $script:CacheExpiration.ContainsKey($DataType) -and
        $currentTime -lt $script:CacheExpiration[$DataType]) {
        
        return $script:SystemDataCache[$DataType]
    }
    
    return $null
}

function Set-CachedData {
    <#
    .SYNOPSIS
        Store data in cache with expiration
    #>
    param(
        [string]$DataType,
        [object]$Data
    )
    
    $currentTime = Get-Date
    $script:SystemDataCache[$DataType] = $Data
    
    # Set expiration time
    if ($script:CacheDurations.ContainsKey($DataType)) {
        $script:CacheExpiration[$DataType] = $currentTime.AddSeconds($script:CacheDurations[$DataType])
    } else {
        $script:CacheExpiration[$DataType] = $currentTime.AddSeconds(60) # Default 1 minute
    }
}

function Start-BackgroundDataCollection {
    <#
    .SYNOPSIS
        Start background data collection to avoid blocking UI
    #>
    
    $script:DataCollectionTimer = New-Object System.Windows.Forms.Timer
    $script:DataCollectionTimer.Interval = 15000  # 15 seconds
    
    $script:DataCollectionTimer.Add_Tick({
        try {
            # Collect data in background thread to avoid UI blocking
            Start-Job -Name "DataCollection_$(Get-Date -Format 'HHmmss')" -ScriptBlock {
                param($BasePath)
                
                # Import necessary modules in background job
                $SystemLoggerPath = Join-Path $BasePath "SystemLogger.ps1"
                if (Test-Path $SystemLoggerPath) {
                    . $SystemLoggerPath
                }
                
                # Collect system data
                $systemData = @{}
                
                try {
                    # Basic system info (cache for longer)
                    $os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption,Version,FreePhysicalMemory,TotalVisibleMemorySize,LastBootUpTime
                    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -Property Name,TotalPhysicalMemory
                    $cpu = Get-CimInstance -ClassName Win32_Processor -Property Name | Select-Object -First 1
                    
                    # Performance counters (quick snapshot)
                    $cpuCounter = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                    $cpuUsage = if ($cpuCounter) { [math]::Round($cpuCounter.CounterSamples.CookedValue, 1) } else { 0 }
                    
                    $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
                    
                    $systemData['SystemOverview'] = @{
                        ComputerName = $cs.Name
                        OS           = $os.Caption
                        OSVersion    = $os.Version
                        CPU          = $cpu.Name
                        TotalRAM     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
                        CPUUsage     = $cpuUsage
                        MemoryUsage  = $memoryUsage
                        Uptime       = ((Get-Date) - $os.LastBootUpTime).ToString("dd\.hh\:mm")
                    }
                    
                    # Driver health (less frequent)
                    $problemDevices = @(Get-CimInstance -ClassName Win32_PnPEntity -Property ConfigManagerErrorCode,PNPDeviceID | Where-Object { 
                        $_.ConfigManagerErrorCode -ne 0 
                    })
                    
                    $allPCIDevices = @(Get-CimInstance -ClassName Win32_PnPEntity -Property PNPDeviceID | Where-Object { 
                        $_.PNPDeviceID -like "PCI*" 
                    })
                    
                    $totalDevices = $allPCIDevices.Count
                    $problemCount = $problemDevices.Count
                    $healthScore = if ($totalDevices -gt 0) { 
                        [math]::Round((($totalDevices - $problemCount) / $totalDevices) * 100, 1) 
                    } else { 100 }
                    
                    $systemData['DriverHealth'] = @{
                        TotalDevices   = $totalDevices
                        ProblemDevices = $problemCount
                        HealthScore    = $healthScore
                        Status         = if ($healthScore -ge 90) { "Good" } elseif ($healthScore -ge 70) { "Fair" } else { "Poor" }
                    }
                    
                    return $systemData
                }
                catch {
                    return @{ Error = $_.Exception.Message }
                }
            } -ArgumentList $script:BasePath
        }
        catch {
            Write-Host "Error starting background data collection: $($_.Exception.Message)" -ForegroundColor Red
        }
    })
    
    $script:DataCollectionTimer.Start()
}

function Start-OptimizedUIUpdates {
    <#
    .SYNOPSIS
        Start optimized UI update timer that only updates when needed
    #>
    
    $script:UIUpdateTimer = New-Object System.Windows.Forms.Timer
    $script:UIUpdateTimer.Interval = 2000  # 2 seconds for UI updates
    
    $script:UIUpdateTimer.Add_Tick({
        try {
            # Check for completed background jobs
            $completedJobs = Get-Job | Where-Object { $_.State -eq 'Completed' -and $_.Name -like 'DataCollection_*' }
            
            foreach ($job in $completedJobs) {
                try {
                    $result = Receive-Job $job
                    Remove-Job $job
                    
                    if ($result -and -not $result.Error) {
                        # Update cache with new data
                        foreach ($dataType in $result.Keys) {
                            Set-CachedData -DataType $dataType -Data $result[$dataType]
                        }
                        
                        # Update UI only if form is available and visible
                        if ($script:MainForm -and -not $script:MainForm.IsDisposed -and $script:MainForm.Visible) {
                            Update-UIWithCachedData
                        }
                    }
                }
                catch {
                    Remove-Job $job -Force
                }
            }
            
            # Clean up failed jobs
            $failedJobs = Get-Job | Where-Object { $_.State -eq 'Failed' -and $_.Name -like 'DataCollection_*' }
            foreach ($job in $failedJobs) {
                Remove-Job $job -Force
            }
        }
        catch {
            # Silently handle timer errors
        }
    })
    
    $script:UIUpdateTimer.Start()
}

function Update-UIWithCachedData {
    <#
    .SYNOPSIS
        Update UI elements with cached data (non-blocking)
    #>
    
    try {
        # Only update if form is available
        if (-not $script:MainForm -or $script:MainForm.IsDisposed) {
            return
        }
        
        # Throttle UI updates to prevent excessive refreshing
        $timeSinceLastUpdate = (Get-Date) - $script:LastUIUpdate
        if ($timeSinceLastUpdate.TotalSeconds -lt 1) {
            return  # Skip if updated less than 1 second ago
        }
        
        $script:LastUIUpdate = Get-Date
        
        # Get cached data
        $systemData = Get-CachedData -DataType 'SystemOverview'
        $driverHealth = Get-CachedData -DataType 'DriverHealth'
        
        if ($systemData -or $driverHealth) {
            # Update UI on the main thread
            $script:MainForm.Invoke([Action] {
                try {
                    if ($systemData) {
                        Update-PerformanceCards -SystemData $systemData
                    }
                    
                    if ($driverHealth) {
                        Update-DriverHealthCard -DriverHealth $driverHealth
                    }
                    
                    # Update timestamp in log occasionally
                    if ((Get-Date).Second % 30 -eq 0) {
                        Add-LogMessage "System monitoring active - Cached data updated"
                    }
                }
                catch {
                    # Silently handle UI update errors
                }
            })
        }
    }
    catch {
        # Silently handle errors to prevent crashes
    }
}

function Update-PerformanceCards {
    <#
    .SYNOPSIS
        Update performance cards with new data
    #>
    param($SystemData)
    
    # This function will be integrated with the main GUI to update specific cards
    # For now, it's a placeholder that would update CPU and Memory cards
}

function Update-DriverHealthCard {
    <#
    .SYNOPSIS
        Update driver health card with new data
    #>
    param($DriverHealth)
    
    # This function will be integrated with the main GUI to update driver health card
    # For now, it's a placeholder that would update the driver status display
}

function Get-OptimizedSystemOverview {
    <#
    .SYNOPSIS
        Get system overview data with caching for better performance
    #>
    
    # Try to get cached data first
    $cachedData = Get-CachedData -DataType 'SystemOverview'
    if ($cachedData) {
        return $cachedData
    }
    
    # If no cached data, get fresh data (this will be less frequent)
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        # Get performance counters
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
        $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        
        $systemData = @{
            ComputerName = $cs.Name
            OS           = $os.Caption
            OSVersion    = $os.Version
            CPU          = $cpu.Name
            TotalRAM     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            CPUUsage     = [math]::Round($cpuUsage, 1)
            MemoryUsage  = $memoryUsage
            Uptime       = ((Get-Date) - $os.LastBootUpTime).ToString("dd\.hh\:mm")
        }
        
        # Cache the data
        Set-CachedData -DataType 'SystemOverview' -Data $systemData
        
        return $systemData
    }
    catch {
        Write-Host "Error getting system overview: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-OptimizedDriverHealthSummary {
    <#
    .SYNOPSIS
        Get driver health summary with caching
    #>
    
    # Try to get cached data first
    $cachedData = Get-CachedData -DataType 'DriverHealth'
    if ($cachedData) {
        return $cachedData
    }
    
    # If no cached data, get fresh data
    try {
        $problemDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.ConfigManagerErrorCode -ne 0 
        }
        
        $allPCIDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.PNPDeviceID -like "PCI*" 
        }
        
        $totalDevices = $allPCIDevices.Count
        $problemCount = $problemDevices.Count
        $healthScore = if ($totalDevices -gt 0) { 
            [math]::Round((($totalDevices - $problemCount) / $totalDevices) * 100, 1) 
        } else { 100 }
        
        $driverData = @{
            TotalDevices   = $totalDevices
            ProblemDevices = $problemCount
            HealthScore    = $healthScore
            Status         = if ($healthScore -ge 90) { "Good" } elseif ($healthScore -ge 70) { "Fair" } else { "Poor" }
        }
        
        # Cache the data
        Set-CachedData -DataType 'DriverHealth' -Data $driverData
        
        return $driverData
    }
    catch {
        Write-Host "Error getting driver health: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            TotalDevices   = 0
            ProblemDevices = 0
            HealthScore    = 100
            Status         = "Unknown"
        }
    }
}

# Note: Functions exported for use by main GUI
# Available functions:
# - Initialize-PerformanceOptimizations
# - Stop-PerformanceOptimizations  
# - Get-OptimizedSystemOverview
# - Get-OptimizedDriverHealthSummary
# - Get-CachedData
# - Set-CachedData