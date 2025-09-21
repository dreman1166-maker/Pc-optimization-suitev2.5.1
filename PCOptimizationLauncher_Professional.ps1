#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    PC Optimization Suite Launcher v2.5.0 - Professional Edition
    
.DESCRIPTION
    Advanced launcher integrating Phase 1 intelligence and Phase 2 GUI interface.
    Provides both graphical and console interfaces for comprehensive PC optimization.
    
.AUTHOR
    PC Optimization Suite Team
    
.VERSION
    2.5.0 - Professional Edition with GUI
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Console,
    
    [Parameter(Mandatory=$false)]
    [switch]$GUI,
    
    [Parameter(Mandatory=$false)]
    [switch]$QuickScan,
    
    [Parameter(Mandatory=$false)]
    [switch]$Benchmark
)

# Global Variables
$script:ModuleVersion = "2.5.0"
$script:BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$script:DataPath = Join-Path $script:BasePath "Data"
$script:LogPath = Join-Path $script:BasePath "Logs"

# Ensure directories exist
@($script:DataPath, $script:LogPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

function Write-LauncherLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $script:LogPath "Launcher_$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor White }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
}

function Show-StartupBanner {
    Clear-Host
    Write-Host ""
    Write-Host "################################################################" -ForegroundColor Cyan
    Write-Host "#                                                              #" -ForegroundColor Cyan
    Write-Host "#        PC OPTIMIZATION SUITE v$script:ModuleVersion - PROFESSIONAL EDITION        #" -ForegroundColor Cyan
    Write-Host "#                                                              #" -ForegroundColor Cyan
    Write-Host "#        Phase 1: Advanced Intelligence ✓                     #" -ForegroundColor Green
    Write-Host "#        Phase 2: Professional Interface ✓                    #" -ForegroundColor Green
    Write-Host "#                                                              #" -ForegroundColor Cyan
    Write-Host "################################################################" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Launch GUI Interface (Recommended)" -ForegroundColor Green
    Write-Host "2. Quick System Scan" -ForegroundColor White
    Write-Host "3. Run Performance Benchmark" -ForegroundColor White
    Write-Host "4. Advanced Driver Intelligence" -ForegroundColor White
    Write-Host "5. System Optimization (Console)" -ForegroundColor White
    Write-Host "6. Console Mode (Advanced Users)" -ForegroundColor Gray
    Write-Host "7. Exit" -ForegroundColor Red
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (1-7)"
        $validChoice = $choice -match '^[1-7]$'
        if (-not $validChoice) {
            Write-Host "Invalid choice. Please enter a number between 1 and 7." -ForegroundColor Red
        }
    } while (-not $validChoice)
    
    return [int]$choice
}

function Start-GUI {
    Write-LauncherLog "Launching GUI interface..." -Level Info
    
    try {
        $guiScript = Join-Path $script:BasePath "PCOptimizationGUI.ps1"
        if (Test-Path $guiScript) {
            Write-LauncherLog "Starting professional GUI interface" -Level Success
            & $guiScript
        } else {
            Write-LauncherLog "GUI script not found, falling back to console" -Level Warning
            Start-Console
        }
    } catch {
        Write-LauncherLog "Error launching GUI: $($_.Exception.Message)" -Level Error
        Write-LauncherLog "Falling back to console mode" -Level Warning
        Start-Console
    }
}

function Start-QuickScan {
    Write-LauncherLog "Starting quick system scan..." -Level Info
    
    try {
        # System Overview
        Write-Host "Analyzing system..." -ForegroundColor Yellow
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        
        Write-Host "✓ System Information:" -ForegroundColor Green
        Write-Host "  Computer: $($cs.Name)" -ForegroundColor White
        Write-Host "  OS: $($os.Caption)" -ForegroundColor White
        Write-Host "  RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB" -ForegroundColor White
        
        # Driver Health
        Write-Host ""
        Write-Host "Checking driver health..." -ForegroundColor Yellow
        $problemDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.ConfigManagerErrorCode -ne 0 
        }
        $allPCIDevices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.PNPDeviceID -like "PCI*" 
        }
        
        $healthScore = if ($allPCIDevices.Count -gt 0) {
            [math]::Round((($allPCIDevices.Count - $problemDevices.Count) / $allPCIDevices.Count) * 100, 1)
        } else { 100 }
        
        Write-Host "✓ Driver Health: $healthScore%" -ForegroundColor $(if ($healthScore -gt 95) { "Green" } elseif ($healthScore -gt 80) { "Yellow" } else { "Red" })
        Write-Host "  Total Devices: $($allPCIDevices.Count)" -ForegroundColor White
        Write-Host "  Problem Devices: $($problemDevices.Count)" -ForegroundColor White
        
        # Performance Check
        Write-Host ""
        Write-Host "Checking performance..." -ForegroundColor Yellow
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
        $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        
        Write-Host "✓ Current Performance:" -ForegroundColor Green
        Write-Host "  CPU Usage: $([math]::Round($cpuUsage, 1))%" -ForegroundColor White
        Write-Host "  Memory Usage: $memoryUsage%" -ForegroundColor White
        
        Write-LauncherLog "Quick scan completed successfully" -Level Success
        
    } catch {
        Write-LauncherLog "Error during quick scan: $($_.Exception.Message)" -Level Error
    }
}

function Start-Benchmark {
    Write-LauncherLog "Starting performance benchmark..." -Level Info
    
    try {
        $benchmarkScript = Join-Path $script:BasePath "DriverIntelligenceDemo.ps1"
        if (Test-Path $benchmarkScript) {
            Write-Host "Running comprehensive performance benchmark..." -ForegroundColor Yellow
            & $benchmarkScript
            Write-LauncherLog "Benchmark completed successfully" -Level Success
        } else {
            Write-LauncherLog "Benchmark script not found" -Level Error
        }
    } catch {
        Write-LauncherLog "Error during benchmark: $($_.Exception.Message)" -Level Error
    }
}

function Start-DriverIntelligence {
    Write-LauncherLog "Starting Advanced Driver Intelligence..." -Level Info
    
    try {
        $driverScript = Join-Path $script:BasePath "DriverIntelligenceDemo.ps1"
        if (Test-Path $driverScript) {
            Write-Host "Running Advanced Driver Intelligence analysis..." -ForegroundColor Yellow
            & $driverScript
            Write-LauncherLog "Driver analysis completed successfully" -Level Success
        } else {
            Write-LauncherLog "Driver intelligence script not found" -Level Error
        }
    } catch {
        Write-LauncherLog "Error during driver analysis: $($_.Exception.Message)" -Level Error
    }
}

function Start-SystemOptimization {
    Write-LauncherLog "Starting system optimization..." -Level Info
    
    try {
        # Simple optimization routine
        Write-Host "Running basic system optimization..." -ForegroundColor Yellow
        
        Write-Host "✓ Clearing temporary files..." -ForegroundColor Green
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        Write-Host "✓ Clearing browser cache..." -ForegroundColor Green
        # Clear common browser caches (safely)
        $cachePaths = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        )
        
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "✓ Optimization completed!" -ForegroundColor Green
        Write-LauncherLog "System optimization completed successfully" -Level Success
        
    } catch {
        Write-LauncherLog "Error during optimization: $($_.Exception.Message)" -Level Error
    }
}

function Start-Console {
    Write-LauncherLog "Launching console interface..." -Level Info
    
    Write-Host ""
    Write-Host "=== CONSOLE MODE ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    Write-Host "- scan: Quick system scan" -ForegroundColor White
    Write-Host "- benchmark: Performance benchmark" -ForegroundColor White
    Write-Host "- drivers: Driver analysis" -ForegroundColor White
    Write-Host "- optimize: System optimization" -ForegroundColor White
    Write-Host "- gui: Launch GUI interface" -ForegroundColor White
    Write-Host "- exit: Exit application" -ForegroundColor White
    Write-Host ""
    
    do {
        $command = Read-Host "PC-Optimizer"
        
        switch ($command.ToLower()) {
            "scan" { Start-QuickScan }
            "benchmark" { Start-Benchmark }
            "drivers" { Start-DriverIntelligence }
            "optimize" { Start-SystemOptimization }
            "gui" { Start-GUI; break }
            "exit" { break }
            "help" { 
                Write-Host "Available commands: scan, benchmark, drivers, optimize, gui, exit" -ForegroundColor Yellow
            }
            default { 
                Write-Host "Unknown command: $command. Type 'help' for available commands." -ForegroundColor Red
            }
        }
        Write-Host ""
    } while ($command.ToLower() -ne "exit")
}

# Main Execution
try {
    Show-StartupBanner
    
    Write-LauncherLog "PC Optimization Suite v$script:ModuleVersion starting..." -Level Info
    Write-LauncherLog "Phase 1 (Intelligence) and Phase 2 (GUI) features available" -Level Info
    
    # Handle command line parameters
    if ($QuickScan) {
        Start-QuickScan
        return
    }
    
    if ($Benchmark) {
        Start-Benchmark
        return
    }
    
    if ($Console) {
        Start-Console
        return
    }
    
    if ($GUI) {
        Start-GUI
        return
    }
    
    # Show interactive menu
    do {
        $choice = Show-MainMenu
        
        switch ($choice) {
            1 { Start-GUI }
            2 { Start-QuickScan }
            3 { Start-Benchmark }
            4 { Start-DriverIntelligence }
            5 { Start-SystemOptimization }
            6 { Start-Console }
            7 { 
                Write-LauncherLog "Exiting PC Optimization Suite" -Level Info
                Write-Host "Thank you for using PC Optimization Suite!" -ForegroundColor Green
                return
            }
        }
        
        if ($choice -ne 7) {
            Write-Host ""
            Write-Host "Press any key to return to main menu..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Show-StartupBanner
        }
        
    } while ($choice -ne 7)
    
} catch {
    Write-LauncherLog "Critical error in launcher: $($_.Exception.Message)" -Level Error
    Write-Host "A critical error occurred. Please check the logs for details." -ForegroundColor Red
    exit 1
}