#Requires -Version 5.1
#Requires -RunAsAdministrator

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Advanced Driver Intelligence v2.1.0 - Demo" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Create directories
$BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$LogPath = Join-Path $BasePath "Logs"
$DataPath = Join-Path $BasePath "Data"

@($LogPath, $DataPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

Write-Host "Creating hardware fingerprint..." -ForegroundColor Green

try {
    # Get system info
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $system = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    
    $fingerprint = @{
        CPU = @{
            Name = $cpu.Name
            Cores = $cpu.NumberOfCores
        }
        System = @{
            Manufacturer = $system.Manufacturer
            Model = $system.Model
            OSName = $os.Caption
        }
        Timestamp = Get-Date
    }
    
    # Create unique ID
    $jsonString = $fingerprint | ConvertTo-Json -Compress
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($jsonString))
    $fingerprint.UniqueID = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    
    # Save fingerprint
    $fingerprintPath = Join-Path $DataPath "HardwareFingerprint.json"
    $fingerprint | ConvertTo-Json | Set-Content -Path $fingerprintPath -Encoding UTF8
    
    Write-Host "Hardware fingerprint created!" -ForegroundColor Green
    Write-Host "   System ID: $($fingerprint.UniqueID.Substring(0,16))..." -ForegroundColor White
    Write-Host "   CPU: $($fingerprint.CPU.Name)" -ForegroundColor White
    Write-Host "   System: $($fingerprint.System.Manufacturer) $($fingerprint.System.Model)" -ForegroundColor White
    Write-Host "   OS: $($fingerprint.System.OSName)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Running performance benchmark..." -ForegroundColor Green

try {
    # Simple CPU test
    $start = Get-Date
    $iterations = 0
    $endTime = $start.AddSeconds(5)
    
    while ((Get-Date) -lt $endTime) {
        [math]::Sqrt([math]::PI)
        $iterations++
    }
    
    $duration = ((Get-Date) - $start).TotalSeconds
    $ips = [math]::Round($iterations / $duration, 0)
    
    Write-Host "CPU Performance Test Complete!" -ForegroundColor Green
    Write-Host "   Iterations: $iterations" -ForegroundColor White
    Write-Host "   Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
    Write-Host "   Performance: $ips iterations/second" -ForegroundColor White
    
} catch {
    Write-Host "❌ Benchmark Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Analyzing system drivers..." -ForegroundColor Green

try {
    # Check for problem devices
    $problemDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
        $_.ConfigManagerErrorCode -ne 0 
    }
    
    $allPCIDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
        $_.PNPDeviceID -like "PCI*" 
    }
    
    $totalDevices = $allPCIDevices.Count
    $problemCount = $problemDevices.Count
    $healthScore = [math]::Round((($totalDevices - $problemCount) / $totalDevices) * 100, 1)
    
    Write-Host "Driver Analysis Complete!" -ForegroundColor Green
    Write-Host "   Total PCI Devices: $totalDevices" -ForegroundColor White
    Write-Host "   Problem Devices: $problemCount" -ForegroundColor $(if ($problemCount -eq 0) { "Green" } else { "Red" })
    Write-Host "   System Health: $healthScore%" -ForegroundColor $(if ($healthScore -gt 95) { "Green" } elseif ($healthScore -gt 80) { "Yellow" } else { "Red" })
    
    if ($problemCount -gt 0) {
        Write-Host ""
        Write-Host "Problem Devices Found:" -ForegroundColor Yellow
        foreach ($device in $problemDevices | Select-Object -First 5) {
            Write-Host "   • $($device.Name) (Error: $($device.ConfigManagerErrorCode))" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "❌ Analysis Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Advanced Driver Intelligence Demo Complete!" -ForegroundColor Green
Write-Host "Data saved in: $DataPath" -ForegroundColor Gray
Write-Host ""