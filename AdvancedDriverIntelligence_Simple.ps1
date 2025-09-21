#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Advanced Driver Intelligence System v2.1.0 - Simplified Version
    
.DESCRIPTION
    Intelligent driver detection, compatibility checking, and hardware fingerprinting system.
    
.AUTHOR
    PC Optimization Suite Team
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$CreateFingerprint,
    
    [Parameter(Mandatory=$false)]
    [switch]$BenchmarkMode,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedAnalysis
)

# Global Variables
$script:ModuleVersion = "2.1.0"
$script:BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$script:LogPath = Join-Path $script:BasePath "Logs"
$script:DataPath = Join-Path $script:BasePath "Data"

# Ensure directories exist
@($script:LogPath, $script:DataPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

function Write-IntelligenceLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $script:LogPath "DriverIntelligence_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor White }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

function Get-HardwareFingerprint {
    Write-IntelligenceLog "🔍 Creating hardware fingerprint..." -Level Info
    
    $fingerprint = @{}
    
    try {
        # CPU Information
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        $fingerprint.CPU = @{
            Name = $cpu.Name
            Manufacturer = $cpu.Manufacturer
            Cores = $cpu.NumberOfCores
            LogicalCores = $cpu.NumberOfLogicalProcessors
        }
        
        # GPU Information
        $gpus = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.PNPDeviceID -like "PCI*" }
        $fingerprint.GPU = @()
        foreach ($gpu in $gpus) {
            $fingerprint.GPU += @{
                Name = $gpu.Name
                DeviceID = $gpu.DeviceID
                DriverVersion = $gpu.DriverVersion
            }
        }
        
        # System Information
        $system = Get-CimInstance -ClassName Win32_ComputerSystem
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $fingerprint.System = @{
            Manufacturer = $system.Manufacturer
            Model = $system.Model
            OSName = $os.Caption
            OSVersion = $os.Version
        }
        
        # Create unique hash
        $jsonString = $fingerprint | ConvertTo-Json -Depth 5 -Compress
        $hash = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($jsonString))
        $fingerprint.UniqueID = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        
        # Save fingerprint
        $fingerprintPath = Join-Path $script:DataPath "HardwareFingerprint.json"
        $fingerprint | ConvertTo-Json -Depth 5 | Set-Content -Path $fingerprintPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Hardware fingerprint created successfully" -Level Success
        Write-IntelligenceLog "🆔 System ID: $($fingerprint.UniqueID.Substring(0,16))..." -Level Info
        
        return $fingerprint
        
    } catch {
        Write-IntelligenceLog "❌ Error creating hardware fingerprint: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Get-DriverAnalysis {
    Write-IntelligenceLog "🔍 Starting driver analysis..." -Level Info
    
    $analysis = @{
        Timestamp = Get-Date
        Drivers = @()
        Summary = @{}
    }
    
    try {
        # Get problematic devices
        $problemDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.ConfigManagerErrorCode -ne 0 
        }
        
        # Get all PCI devices
        $allDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.PNPDeviceID -like "PCI*" 
        }
        
        $totalDevices = $allDevices.Count
        $problemCount = $problemDevices.Count
        $workingCount = $totalDevices - $problemCount
        
        $analysis.Summary = @{
            TotalDevices = $totalDevices
            WorkingDevices = $workingCount
            ProblematicDevices = $problemCount
            HealthScore = [math]::Round(($workingCount / $totalDevices) * 100, 1)
        }
        
        # Add problem device details
        foreach ($device in $problemDevices) {
            $analysis.Drivers += @{
                Name = $device.Name
                Status = $device.Status
                ErrorCode = $device.ConfigManagerErrorCode
                DeviceID = $device.PNPDeviceID
            }
        }
        
        # Save analysis
        $analysisPath = Join-Path $script:DataPath "DriverAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $analysis | ConvertTo-Json -Depth 5 | Set-Content -Path $analysisPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Driver analysis completed" -Level Success
        
        return $analysis
        
    } catch {
        Write-IntelligenceLog "❌ Error during driver analysis: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Start-PerformanceBenchmark {
    Write-IntelligenceLog "🏃‍♂️ Starting performance benchmark..." -Level Info
    
    $benchmark = @{
        Timestamp = Get-Date
        Results = @{}
    }
    
    try {
        # CPU Test
        Write-IntelligenceLog "📊 Running CPU test..." -Level Info
        $cpuStart = Get-Date
        $iterations = 0
        $endTime = $cpuStart.AddSeconds(10)
        
        while ((Get-Date) -lt $endTime) {
            [math]::Sqrt([math]::PI * 2)
            $iterations++
        }
        
        $cpuEnd = Get-Date
        $duration = ($cpuEnd - $cpuStart).TotalSeconds
        $benchmark.Results.CPU = @{
            Iterations = $iterations
            Duration = $duration
            IterationsPerSecond = [math]::Round($iterations / $duration, 0)
        }
        
        # Memory Test
        Write-IntelligenceLog "💾 Running memory test..." -Level Info
        $memStart = Get-Date
        $array = New-Object byte[] (50MB)
        for ($i = 0; $i -lt $array.Length; $i += 1000) {
            $array[$i] = 255
        }
        $memEnd = Get-Date
        $memDuration = ($memEnd - $memStart).TotalSeconds
        $benchmark.Results.Memory = @{
            Size = $array.Length
            Duration = $memDuration
            Speed = [math]::Round(($array.Length / $memDuration) / 1MB, 2)
        }
        
        # Calculate overall score
        $cpuScore = [math]::Min(500, ($benchmark.Results.CPU.IterationsPerSecond / 100000) * 500)
        $memScore = [math]::Min(500, ($benchmark.Results.Memory.Speed / 100) * 500)
        $benchmark.OverallScore = [math]::Round($cpuScore + $memScore, 0)
        
        # Save benchmark
        $benchmarkPath = Join-Path $script:DataPath "Benchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $benchmark | ConvertTo-Json -Depth 5 | Set-Content -Path $benchmarkPath -Encoding UTF8
        
        Write-IntelligenceLog "✅ Performance benchmark completed" -Level Success
        
        return $benchmark
        
    } catch {
        Write-IntelligenceLog "❌ Error during benchmark: $($_.Exception.Message)" -Level Error
        return $null
    }
}

# Main execution
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Advanced Driver Intelligence v$script:ModuleVersion" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-IntelligenceLog "🚀 Starting Advanced Driver Intelligence system..." -Level Info

try {
    # Create hardware fingerprint
    if ($CreateFingerprint) {
        $fingerprint = Get-HardwareFingerprint
        if ($fingerprint) {
            Write-Host ""
            Write-Host "🆔 Hardware Fingerprint Created:" -ForegroundColor Green
            Write-Host "   System ID: $($fingerprint.UniqueID.Substring(0,16))..." -ForegroundColor White
            Write-Host "   CPU: $($fingerprint.CPU.Name)" -ForegroundColor White
            Write-Host "   OS: $($fingerprint.System.OSName)" -ForegroundColor White
        }
    }
    
    # Run performance benchmark
    if ($BenchmarkMode) {
        $benchmark = Start-PerformanceBenchmark
        if ($benchmark) {
            Write-Host ""
            Write-Host "📊 Performance Benchmark Results:" -ForegroundColor Green
            Write-Host "   Overall Score: $($benchmark.OverallScore)/1000" -ForegroundColor White
            Write-Host "   CPU Performance: $($benchmark.Results.CPU.IterationsPerSecond) iterations/sec" -ForegroundColor White
            Write-Host "   Memory Speed: $($benchmark.Results.Memory.Speed) MB/s" -ForegroundColor White
        }
    }
    
    # Run driver analysis
    if ($DetailedAnalysis) {
        $analysis = Get-DriverAnalysis
        if ($analysis) {
            Write-Host ""
            Write-Host "🔍 Driver Analysis Summary:" -ForegroundColor Green
            Write-Host "   Total Devices: $($analysis.Summary.TotalDevices)" -ForegroundColor White
            Write-Host "   Working Devices: $($analysis.Summary.WorkingDevices)" -ForegroundColor Green
            Write-Host "   Problematic Devices: $($analysis.Summary.ProblematicDevices)" -ForegroundColor $(if ($analysis.Summary.ProblematicDevices -eq 0) { "Green" } else { "Red" })
            Write-Host "   System Health: $($analysis.Summary.HealthScore)%" -ForegroundColor $(if ($analysis.Summary.HealthScore -gt 90) { "Green" } elseif ($analysis.Summary.HealthScore -gt 70) { "Yellow" } else { "Red" })
        }
    }
    
    Write-Host ""
    Write-IntelligenceLog "✅ Advanced Driver Intelligence completed successfully" -Level Success
    Write-Host "🎉 Advanced Driver Intelligence completed successfully!" -ForegroundColor Green
    Write-Host "📁 Results saved in: $script:DataPath" -ForegroundColor Gray
    
} catch {
    Write-IntelligenceLog "❌ Critical error: $($_.Exception.Message)" -Level Error
    Write-Host "❌ An error occurred. Please check the logs for details." -ForegroundColor Red
    exit 1
}