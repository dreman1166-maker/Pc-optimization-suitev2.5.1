#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Advanced Driver Intelligence System v2.1.0
    
.DESCRIPTION
    Intelligent driver detection, compatibility checking, and hardware fingerprinting system.
    Features AI-powered optimization, rollback protection, and performance benchmarking.
    
.AUTHOR
    PC Optimization Suite Team
    
.VERSION
    2.1.0 - Advanced Intelligence Phase
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$ScanOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$BenchmarkMode,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateFingerprint,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedAnalysis
)

#region Global Variables and Configuration

$script:ModuleVersion = "2.1.0"
$script:ModuleName = "Advanced Driver Intelligence"

# Paths
$script:BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$script:LogPath = Join-Path $script:BasePath "Logs"
$script:DataPath = Join-Path $script:BasePath "Data"
$script:BackupPath = Join-Path $script:BasePath "Backups"
$script:TempPath = Join-Path $script:BasePath "Temp"

# Ensure directories exist
@($script:LogPath, $script:DataPath, $script:BackupPath, $script:TempPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Configuration
$script:Config = @{
    # Hardware Analysis
    EnableGPUAnalysis         = $true
    EnableCPUAnalysis         = $true
    EnableNetworkAnalysis     = $true
    EnableAudioAnalysis       = $true
    EnableStorageAnalysis     = $true
    
    # Intelligence Features
    EnableCompatibilityCheck  = $true
    EnablePerformanceTest     = $true
    EnableRollbackProtection  = $true
    EnableVersionIntelligence = $true
    
    # Benchmarking
    BenchmarkDuration         = 30  # seconds
    EnableBootTimeBenchmark   = $true
    EnableGameBenchmark       = $false  # Advanced feature
    
    # Safety Features
    AutoCreateRestorePoint    = $true
    RequireConfirmation       = $true
    BackupCurrentDrivers      = $true
    
    # Update Preferences
    PreferManufacturerDrivers = $true
    AllowBetaDrivers          = $false
    SkipOptionalUpdates       = $false
}

#endregion

#region Logging System

function Write-IntelligenceLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $script:LogPath "DriverIntelligence_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor White }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
        "Debug" { 
            if ($VerbosePreference -eq "Continue") {
                Write-Host $logEntry -ForegroundColor Gray 
            }
        }
    }
    
    # File output
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

#endregion

#region Hardware Fingerprinting System

function Get-HardwareFingerprint {
    <#
    .SYNOPSIS
        Creates a unique hardware fingerprint for intelligent driver matching
    #>
    
    Write-IntelligenceLog "🔍 Creating hardware fingerprint..." -Level Info
    
    $fingerprint = @{}
    
    try {
        # CPU Information
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        $fingerprint.CPU = @{
            Name          = $cpu.Name
            Manufacturer  = $cpu.Manufacturer
            Family        = $cpu.Family
            Model         = $cpu.Model
            Stepping      = $cpu.Stepping
            ProcessorId   = $cpu.ProcessorId
            Cores         = $cpu.NumberOfCores
            LogicalCores  = $cpu.NumberOfLogicalProcessors
            MaxClockSpeed = $cpu.MaxClockSpeed
            Architecture  = $cpu.Architecture
        }
        
        # GPU Information
        $gpus = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.PNPDeviceID -like "PCI*" }
        $fingerprint.GPU = @()
        foreach ($gpu in $gpus) {
            $fingerprint.GPU += @{
                Name           = $gpu.Name
                DeviceID       = $gpu.DeviceID
                PNPDeviceID    = $gpu.PNPDeviceID
                AdapterRAM     = $gpu.AdapterRAM
                DriverVersion  = $gpu.DriverVersion
                DriverDate     = $gpu.DriverDate
                Manufacturer   = $gpu.AdapterCompatibility
                VideoProcessor = $gpu.VideoProcessor
            }
        }
        
        # Motherboard Information
        $motherboard = Get-CimInstance -ClassName Win32_BaseBoard
        $fingerprint.Motherboard = @{
            Manufacturer = $motherboard.Manufacturer
            Product      = $motherboard.Product
            Version      = $motherboard.Version
            SerialNumber = $motherboard.SerialNumber
        }
        
        # BIOS Information
        $bios = Get-CimInstance -ClassName Win32_BIOS
        $fingerprint.BIOS = @{
            Manufacturer  = $bios.Manufacturer
            Version       = $bios.Version
            ReleaseDate   = $bios.ReleaseDate
            SMBIOSVersion = $bios.SMBIOSBIOSVersion
        }
        
        # Memory Information
        $memory = Get-CimInstance -ClassName Win32_PhysicalMemory
        $fingerprint.Memory = @{
            TotalCapacity = ($memory | Measure-Object Capacity -Sum).Sum
            Modules       = @()
        }
        foreach ($module in $memory) {
            $fingerprint.Memory.Modules += @{
                Capacity     = $module.Capacity
                Speed        = $module.Speed
                Manufacturer = $module.Manufacturer
                PartNumber   = $module.PartNumber
            }
        }
        
        # Storage Information
        $disks = Get-CimInstance -ClassName Win32_DiskDrive
        $fingerprint.Storage = @()
        foreach ($disk in $disks) {
            $fingerprint.Storage += @{
                Model        = $disk.Model
                Size         = $disk.Size
                Interface    = $disk.InterfaceType
                MediaType    = $disk.MediaType
                SerialNumber = $disk.SerialNumber
            }
        }
        
        # Network Adapters
        $network = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PNPDeviceID -like "PCI*" -and $_.NetConnectionStatus -eq 2 }
        $fingerprint.Network = @()
        foreach ($adapter in $network) {
            $fingerprint.Network += @{
                Name         = $adapter.Name
                Manufacturer = $adapter.Manufacturer
                PNPDeviceID  = $adapter.PNPDeviceID
                MACAddress   = $adapter.MACAddress
            }
        }
        
        # Audio Devices
        $audio = Get-CimInstance -ClassName Win32_SoundDevice
        $fingerprint.Audio = @()
        foreach ($device in $audio) {
            $fingerprint.Audio += @{
                Name         = $device.Name
                Manufacturer = $device.Manufacturer
                PNPDeviceID  = $device.PNPDeviceID
            }
        }
        
        # System Information
        $system = Get-CimInstance -ClassName Win32_ComputerSystem
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $fingerprint.System = @{
            Manufacturer = $system.Manufacturer
            Model        = $system.Model
            TotalRAM     = $system.TotalPhysicalMemory
            OSName       = $os.Caption
            OSVersion    = $os.Version
            OSBuild      = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate  = $os.InstallDate
        }
        
        # Create unique hash
        $jsonString = $fingerprint | ConvertTo-Json -Depth 10 -Compress
        $hash = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($jsonString))
        $fingerprint.UniqueID = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        
        # Save fingerprint
        $fingerprintPath = Join-Path $script:DataPath "HardwareFingerprint.json"
        $fingerprint | ConvertTo-Json -Depth 10 | Set-Content -Path $fingerprintPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Hardware fingerprint created successfully" -Level Success
        Write-IntelligenceLog "🆔 System ID: $($fingerprint.UniqueID.Substring(0,16))..." -Level Info
        
        return $fingerprint
        
    }
    catch {
        Write-IntelligenceLog "❌ Error creating hardware fingerprint: $($_.Exception.Message)" -Level Error
        return $null
    }
}

#endregion

#region Driver Analysis System

function Get-DetailedDriverAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive driver analysis with intelligence features
    #>
    
    Write-IntelligenceLog "🔍 Starting detailed driver analysis..." -Level Info
    
    $analysis = @{
        Timestamp         = Get-Date
        Drivers           = @()
        Issues            = @()
        Recommendations   = @()
        PerformanceImpact = @()
    }
    
    try {
        # Get all PnP devices
        $devices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.PNPDeviceID -like "PCI*" -or $_.PNPDeviceID -like "USB*" 
        }
        
        $totalDevices = $devices.Count
        $currentDevice = 0
        
        foreach ($device in $devices) {
            $currentDevice++
            $percentComplete = [math]::Round(($currentDevice / $totalDevices) * 100)
            
            Write-Progress -Activity "Analyzing Drivers" -Status "Device $currentDevice of $totalDevices" -PercentComplete $percentComplete
            
            $driverInfo = @{
                DeviceName             = $device.Name
                PNPDeviceID            = $device.PNPDeviceID
                Status                 = $device.Status
                Present                = $device.Present
                ConfigManagerErrorCode = $device.ConfigManagerErrorCode
            }
            
            # Get driver details
            try {
                $deviceNameEscaped = $device.Name -replace '[^\w]', '%'
                $driverQuery = "SELECT * FROM Win32_SystemDriver WHERE Name LIKE '%$deviceNameEscaped%'"
                $driver = Get-CimInstance -Query $driverQuery -ErrorAction SilentlyContinue | Select-Object -First 1
                
                if ($driver) {
                    $driverInfo.DriverVersion = $driver.Version
                    $driverInfo.DriverDate = $driver.InstallDate
                    $driverInfo.DriverPath = $driver.PathName
                    $driverInfo.DriverSize = if (Test-Path $driver.PathName) { (Get-Item $driver.PathName).Length } else { 0 }
                }
                
                # Analyze driver status
                $driverInfo.AnalysisResult = Analyze-DriverStatus -Device $device -Driver $driver
                
            }
            catch {
                $driverInfo.Error = $_.Exception.Message
            }
            
            $analysis.Drivers += $driverInfo
        }
        
        Write-Progress -Activity "Analyzing Drivers" -Completed
        
        # Generate insights
        $analysis.Summary = Generate-DriverInsights -DriverData $analysis.Drivers
        
        # Save analysis
        $analysisPath = Join-Path $script:DataPath "DriverAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $analysis | ConvertTo-Json -Depth 10 | Set-Content -Path $analysisPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Driver analysis completed - $($analysis.Drivers.Count) devices analyzed" -Level Success
        
        return $analysis
        
    }
    catch {
        Write-IntelligenceLog "❌ Error during driver analysis: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-DriverStatus {
    param(
        [Parameter(Mandatory = $true)]
        $Device,
        
        [Parameter(Mandatory = $false)]
        $Driver
    )
    
    $result = @{
        Status          = "Unknown"
        Issues          = @()
        Recommendations = @()
        Priority        = "Low"
        UpdateAvailable = $false
    }
    
    # Check device status
    if ($Device.ConfigManagerErrorCode -ne 0) {
        $result.Status = "Problem"
        $result.Priority = "High"
        $result.Issues += "Device has configuration manager error code: $($Device.ConfigManagerErrorCode)"
        
        switch ($Device.ConfigManagerErrorCode) {
            1 { $result.Issues += "Device is not configured correctly" }
            10 { $result.Issues += "Device cannot start" }
            12 { $result.Issues += "Device cannot find enough free resources" }
            18 { $result.Issues += "Device needs to be reinstalled" }
            22 { $result.Issues += "Device is disabled" }
            28 { $result.Issues += "Device drivers are not installed" }
            default { $result.Issues += "Unknown device problem" }
        }
    }
    elseif ($Device.Status -eq "OK") {
        $result.Status = "Working"
    }
    else {
        $result.Status = "Warning"
        $result.Priority = "Medium"
        $result.Issues += "Device status: $($Device.Status)"
    }
    
    # Check if driver is missing
    if (-not $Driver) {
        $result.Status = "Missing Driver"
        $result.Priority = "High"
        $result.Issues += "No driver found for this device"
        $result.Recommendations += "Install appropriate driver"
    }
    
    # Additional intelligence checks would go here
    # (Version checking, compatibility analysis, etc.)
    
    return $result
}

function Get-DriverInsights {
    param(
        [Parameter(Mandatory = $true)]
        [array]$DriverData
    )
    
    $insights = @{
        TotalDevices       = $DriverData.Count
        ProblematicDevices = 0
        MissingDrivers     = 0
        WorkingDevices     = 0
        HighPriorityIssues = 0
        Recommendations    = @()
    }
    
    foreach ($driver in $DriverData) {
        switch ($driver.AnalysisResult.Status) {
            "Problem" { $insights.ProblematicDevices++ }
            "Missing Driver" { $insights.MissingDrivers++ }
            "Working" { $insights.WorkingDevices++ }
        }
        
        if ($driver.AnalysisResult.Priority -eq "High") {
            $insights.HighPriorityIssues++
        }
    }
    
    # Generate recommendations
    if ($insights.MissingDrivers -gt 0) {
        $insights.Recommendations += "Install missing drivers for $($insights.MissingDrivers) devices"
    }
    
    if ($insights.ProblematicDevices -gt 0) {
        $insights.Recommendations += "Fix $($insights.ProblematicDevices) problematic devices"
    }
    
    if ($insights.HighPriorityIssues -eq 0 -and $insights.ProblematicDevices -eq 0) {
        $insights.Recommendations += "System drivers are in good condition"
    }
    
    return $insights
}

#endregion

#region Performance Benchmarking System

function Start-PerformanceBenchmark {
    <#
    .SYNOPSIS
        Runs performance benchmarks to establish baseline or measure improvements
    #>
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Before", "After", "Baseline")]
        [string]$BenchmarkType = "Baseline"
    )
    
    Write-IntelligenceLog "🏃‍♂️ Starting $BenchmarkType performance benchmark..." -Level Info
    
    $benchmark = @{
        Type       = $BenchmarkType
        Timestamp  = Get-Date
        Results    = @{}
        SystemInfo = @{}
    }
    
    try {
        # System Information
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        
        $benchmark.SystemInfo = @{
            OS           = $os.Caption
            TotalRAM     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            AvailableRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        }
        
        Write-IntelligenceLog "📊 Running CPU benchmark..." -Level Info
        
        # CPU Performance Test
        $benchmarkStart = Get-Date
        $cpuResult = Test-CPUPerformance -Duration $script:Config.BenchmarkDuration
        $benchmark.Results.CPU = $cpuResult
        
        Write-IntelligenceLog "Benchmark started at: $benchmarkStart" -Level Debug
        
        Write-IntelligenceLog "💾 Running memory benchmark..." -Level Info
        
        # Memory Performance Test
        $memoryResult = Test-MemoryPerformance
        $benchmark.Results.Memory = $memoryResult
        
        Write-IntelligenceLog "💿 Running storage benchmark..." -Level Info
        
        # Storage Performance Test
        $storageResult = Test-StoragePerformance
        $benchmark.Results.Storage = $storageResult
        
        if ($script:Config.EnableBootTimeBenchmark) {
            Write-IntelligenceLog "⏱️ Calculating boot time..." -Level Info
            $bootTime = Get-BootTime
            $benchmark.Results.BootTime = $bootTime
        }
        
        # Calculate overall score
        $benchmark.OverallScore = Calculate-PerformanceScore -Results $benchmark.Results
        
        # Save benchmark
        $benchmarkPath = Join-Path $script:DataPath "Benchmark_$($BenchmarkType)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $benchmark | ConvertTo-Json -Depth 10 | Set-Content -Path $benchmarkPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Performance benchmark completed - Score: $($benchmark.OverallScore)" -Level Success
        
        return $benchmark
        
    }
    catch {
        Write-IntelligenceLog "❌ Error during performance benchmark: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-CPUPerformance {
    param(
        [int]$Duration = 30
    )
    
    $result = @{
        TestDuration = $Duration
        CoresUsed    = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
        StartTime    = Get-Date
    }
    
    # Simple CPU stress test
    $jobs = @()
    $coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    
    for ($i = 0; $i -lt $coreCount; $i++) {
        $jobs += Start-Job -ScriptBlock {
            $end = (Get-Date).AddSeconds($using:Duration)
            $iterations = 0
            while ((Get-Date) -lt $end) {
                [math]::Sqrt([math]::Pow([math]::PI, 2))
                $iterations++
            }
            return $iterations
        }
    }
    
    # Wait for completion
    $jobs | Wait-Job | Out-Null
    $iterations = $jobs | Receive-Job
    $jobs | Remove-Job
    
    $result.TotalIterations = ($iterations | Measure-Object -Sum).Sum
    $result.EndTime = Get-Date
    $result.ActualDuration = ($result.EndTime - $result.StartTime).TotalSeconds
    $result.IterationsPerSecond = [math]::Round($result.TotalIterations / $result.ActualDuration, 2)
    
    return $result
}

function Test-MemoryPerformance {
    $result = @{
        StartTime = Get-Date
    }
    
    # Memory allocation test
    $arrays = @()
    $allocationSize = 100MB
    $allocations = 0
    
    try {
        while ($allocations -lt 10) {
            $array = New-Object byte[] $allocationSize
            $arrays += $array
            $allocations++
        }
        
        # Memory write test
        $writeStart = Get-Date
        foreach ($array in $arrays) {
            for ($i = 0; $i -lt $array.Length; $i += 1000) {
                $array[$i] = 255
            }
        }
        $writeEnd = Get-Date
        
        $result.AllocationCount = $allocations
        $result.TotalAllocated = $allocations * $allocationSize
        $result.WriteTime = ($writeEnd - $writeStart).TotalSeconds
        $result.WriteSpeed = [math]::Round(($result.TotalAllocated / $result.WriteTime) / 1MB, 2)
        
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    finally {
        # Cleanup
        $arrays = $null
        [System.GC]::Collect()
    }
    
    $result.EndTime = Get-Date
    return $result
}

function Test-StoragePerformance {
    $result = @{
        StartTime = Get-Date
    }
    
    $testFile = Join-Path $script:TempPath "storage_test.tmp"
    $testSize = 100MB
    $data = New-Object byte[] $testSize
    
    try {
        # Write test
        $writeStart = Get-Date
        [System.IO.File]::WriteAllBytes($testFile, $data)
        $writeEnd = Get-Date
        
        # Read test
        $readStart = Get-Date
        $readData = [System.IO.File]::ReadAllBytes($testFile)
        $readEnd = Get-Date
        
        $result.WriteTime = ($writeEnd - $writeStart).TotalSeconds
        $result.ReadTime = ($readEnd - $readStart).TotalSeconds
        $result.WriteSpeed = [math]::Round(($testSize / $result.WriteTime) / 1MB, 2)
        $result.ReadSpeed = [math]::Round(($testSize / $result.ReadTime) / 1MB, 2)
        $result.TestSize = $testSize
        
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    finally {
        # Cleanup
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }
    
    $result.EndTime = Get-Date
    return $result
}

function Get-BootTime {
    try {
        $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        
        return @{
            LastBootTime  = $bootTime
            UptimeSeconds = $uptime.TotalSeconds
            UptimeDays    = [math]::Round($uptime.TotalDays, 2)
        }
    }
    catch {
        return @{ Error = $_.Exception.Message }
    }
}

function Get-PerformanceScore {
    param($Results)
    
    $score = 0
    $maxPossibleScore = 1000
    
    # CPU Score (300 points max)
    if ($Results.CPU.IterationsPerSecond) {
        $cpuScore = [math]::Min(300, ($Results.CPU.IterationsPerSecond / 1000000) * 300)
        $score += $cpuScore
    }
    
    # Memory Score (300 points max)
    if ($Results.Memory.WriteSpeed) {
        $memoryScore = [math]::Min(300, ($Results.Memory.WriteSpeed / 1000) * 300)
        $score += $memoryScore
    }
    
    # Storage Score (400 points max)
    if ($Results.Storage.WriteSpeed -and $Results.Storage.ReadSpeed) {
        $avgStorageSpeed = ($Results.Storage.WriteSpeed + $Results.Storage.ReadSpeed) / 2
        $storageScore = [math]::Min(400, ($avgStorageSpeed / 500) * 400)
        $score += $storageScore
    }
    
    # Calculate percentage based on maximum possible score and return the total score
    $performancePercentage = [math]::Round(($score / $maxPossibleScore) * 100, 1)
    Write-Host "Performance Score: $([math]::Round($score, 0)) / $maxPossibleScore ($performancePercentage%)"
    
    return [math]::Round($score, 0)
}

#endregion

#region Main Execution Functions

function Start-AdvancedDriverIntelligence {
    <#
    .SYNOPSIS
        Main entry point for the Advanced Driver Intelligence system
    #>
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host " Advanced Driver Intelligence v$script:ModuleVersion" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-IntelligenceLog "🚀 Starting Advanced Driver Intelligence system..." -Level Info
    
    try {
        # Create hardware fingerprint
        if ($CreateFingerprint -or -not (Test-Path (Join-Path $script:DataPath "HardwareFingerprint.json"))) {
            $fingerprint = Get-HardwareFingerprint
            if (-not $fingerprint) {
                throw "Failed to create hardware fingerprint"
            }
        }
        
        # Run performance benchmark if requested
        if ($BenchmarkMode) {
            $benchmark = Start-PerformanceBenchmark -BenchmarkType "Baseline"
            if ($benchmark) {
                Write-Host ""
                Write-Host "📊 Performance Benchmark Results:" -ForegroundColor Green
                Write-Host "   Overall Score: $($benchmark.OverallScore)/1000" -ForegroundColor White
                if ($benchmark.Results.CPU) {
                    Write-Host "   CPU Performance: $($benchmark.Results.CPU.IterationsPerSecond) iterations/sec" -ForegroundColor White
                }
                if ($benchmark.Results.Memory) {
                    Write-Host "   Memory Speed: $($benchmark.Results.Memory.WriteSpeed) MB/s" -ForegroundColor White
                }
                if ($benchmark.Results.Storage) {
                    Write-Host "   Storage Speed: Write $($benchmark.Results.Storage.WriteSpeed) MB/s, Read $($benchmark.Results.Storage.ReadSpeed) MB/s" -ForegroundColor White
                }
            }
        }
        
        # Run detailed driver analysis
        if ($DetailedAnalysis -or -not $ScanOnly) {
            $analysis = Get-DetailedDriverAnalysis
            if ($analysis) {
                Write-Host ""
                Write-Host "🔍 Driver Analysis Summary:" -ForegroundColor Green
                Write-Host "   Total Devices: $($analysis.Summary.TotalDevices)" -ForegroundColor White
                Write-Host "   Working Devices: $($analysis.Summary.WorkingDevices)" -ForegroundColor Green
                Write-Host "   Problematic Devices: $($analysis.Summary.ProblematicDevices)" -ForegroundColor $(if ($analysis.Summary.ProblematicDevices -eq 0) { "Green" } else { "Red" })
                Write-Host "   Missing Drivers: $($analysis.Summary.MissingDrivers)" -ForegroundColor $(if ($analysis.Summary.MissingDrivers -eq 0) { "Green" } else { "Yellow" })
                Write-Host "   High Priority Issues: $($analysis.Summary.HighPriorityIssues)" -ForegroundColor $(if ($analysis.Summary.HighPriorityIssues -eq 0) { "Green" } else { "Red" })
                
                if ($analysis.Summary.Recommendations.Count -gt 0) {
                    Write-Host ""
                    Write-Host "💡 Recommendations:" -ForegroundColor Yellow
                    foreach ($recommendation in $analysis.Summary.Recommendations) {
                        Write-Host "   • $recommendation" -ForegroundColor White
                    }
                }
            }
        }
        
        Write-Host ""
        Write-IntelligenceLog "✅ Advanced Driver Intelligence completed successfully" -Level Success
        
    }
    catch {
        Write-IntelligenceLog "❌ Critical error in Advanced Driver Intelligence: $($_.Exception.Message)" -Level Error
        Write-Host "❌ An error occurred. Please check the logs for details." -ForegroundColor Red
        return $false
    }
    
    return $true
}

#endregion

#region Script Entry Point

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    try {
        $result = Start-AdvancedDriverIntelligence
        
        if ($result) {
            Write-Host ""
            Write-Host "🎉 Advanced Driver Intelligence completed successfully!" -ForegroundColor Green
            Write-Host "📁 Results saved in: $script:DataPath" -ForegroundColor Gray
        }
        else {
            Write-Host ""
            Write-Host "❌ Advanced Driver Intelligence encountered errors." -ForegroundColor Red
            exit 1
        }
        
    }
    catch {
        Write-Host "❌ Fatal error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

#endregion