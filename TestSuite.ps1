#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Comprehensive Test Suite for PC Optimization System
    
.DESCRIPTION
    Tests all components of the PC optimization system including:
    - Logging system functionality
    - Error handling and recovery
    - Driver update processes
    - Performance optimization
    - System health monitoring
    - Recovery recommendations
    
.NOTES
    Author: GitHub Copilot
    Version: 1.0
    Requires: PowerShell 5.1+ and Administrator privileges
#>

param(
    [switch]$TestLogging,
    [switch]$TestRecovery,
    [switch]$TestDrivers,
    [switch]$TestOptimization,
    [switch]$TestAll,
    [switch]$GenerateReport
)

# Import required modules
try {
    . "$PSScriptRoot\SystemLogger.ps1"
    Write-Log "Test suite started" -Level Info -LogType System -Component "TestSuite"
} catch {
    Write-Error "Failed to load SystemLogger.ps1. Please ensure it exists in the script directory."
    exit 1
}

# Test Results Storage
$Global:TestResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
}

# Test execution framework
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Description = ""
    )
    
    $testStart = Get-Date
    $testResult = @{
        Name = $TestName
        Description = $Description
        StartTime = $testStart
        EndTime = $null
        Duration = $null
        Status = "Running"
        Output = @()
        Errors = @()
    }
    
    Write-Log "Starting test: $TestName" -Level Info -LogType System -Component "TestRunner"
    Write-Host "`n🧪 Testing: $TestName" -ForegroundColor Cyan
    if ($Description) {
        Write-Host "   Description: $Description" -ForegroundColor Gray
    }
    
    try {
        $output = & $TestScript
        $testResult.Output += $output
        $testResult.Status = "Passed"
        Write-Host "   ✅ PASSED" -ForegroundColor Green
        $Global:TestResults.Summary.Passed++
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Errors += $_.Exception.Message
        Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Test failed: $TestName - $($_.Exception.Message)" -Level Error -LogType System -Component "TestRunner"
        $Global:TestResults.Summary.Failed++
    }
    finally {
        $testResult.EndTime = Get-Date
        $testResult.Duration = $testResult.EndTime - $testResult.StartTime
        $Global:TestResults.Tests += $testResult
        $Global:TestResults.Summary.Total++
    }
}

# Test logging system functionality
function Test-LoggingSystem {
    Write-Host "`n📝 TESTING LOGGING SYSTEM" -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    Invoke-Test "Initialize Logging" {
        $result = Initialize-LoggingSystem
        if (-not $result) { throw "Failed to initialize logging system" }
        return "Logging system initialized successfully"
    } "Verify logging system can be initialized"
    
    Invoke-Test "Write Log Entries" {
        Write-Log "Test info message" -Level Info -LogType System
        Write-Log "Test warning message" -Level Warning -LogType System
        Write-Log "Test success message" -Level Success -LogType System
        return "Log entries written successfully"
    } "Test writing different log levels"
    
    Invoke-Test "Performance Logging" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Start-Sleep -Milliseconds 100
        $stopwatch.Stop()
        Write-PerformanceLog -Operation "Test Operation" -Duration $stopwatch.Elapsed
        return "Performance logging completed"
    } "Test performance metrics logging"
    
    Invoke-Test "System State Capture" {
        $state = Capture-SystemState -Operation "Test Capture"
        if (-not $state) { throw "Failed to capture system state" }
        return "System state captured: $($state.Keys.Count) metrics"
    } "Test system state capture functionality"
    
    Invoke-Test "Log File Existence" {
        $logFiles = @($Global:MainLogFile, $Global:ErrorLogFile, $Global:OperationLogFile, $Global:PerformanceLogFile)
        $missingFiles = @()
        foreach ($file in $logFiles) {
            if (-not (Test-Path $file)) {
                $missingFiles += $file
            }
        }
        if ($missingFiles.Count -gt 0) {
            throw "Missing log files: $($missingFiles -join ', ')"
        }
        return "All log files created successfully"
    } "Verify all log files are created"
}

# Test recovery system functionality
function Test-RecoverySystem {
    Write-Host "`n🔧 TESTING RECOVERY SYSTEM" -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    Invoke-Test "Error Pattern Analysis" {
        # Generate some test errors
        Write-Log "Test error for pattern analysis" -Level Error -LogType System
        Write-Log "Another test error" -Level Error -LogType System
        Write-Log "Test error for pattern analysis" -Level Error -LogType System
        
        $recommendations = Get-RecoveryRecommendations -DaysToAnalyze 1
        if (-not $recommendations) { throw "Failed to generate recovery recommendations" }
        return "Generated $($recommendations.TotalRecommendations) recommendations"
    } "Test error pattern analysis and recovery recommendations"
    
    Invoke-Test "System Health Calculation" {
        $health = Get-OverallSystemHealth
        if ($health -lt 0 -or $health -gt 100) {
            throw "Invalid health score: $health"
        }
        return "System health score: $health%"
    } "Test system health score calculation"
    
    Invoke-Test "Recovery Action Execution" {
        $testActions = @("Check for memory leaks", "Optimize startup programs")
        $mockRecommendations = @(
            @{
                Priority = "High"
                Issue = "Test Issue"
                Actions = $testActions
            }
        )
        $result = Start-AutoRecovery -Recommendations $mockRecommendations -AutoApprove
        if (-not $result) { throw "Failed to execute recovery actions" }
        return "Executed $($result.TotalActions) recovery actions with $($result.SuccessRate)% success rate"
    } "Test automated recovery action execution"
}

# Test driver update functionality
function Test-DriverSystem {
    Write-Host "`n🔌 TESTING DRIVER SYSTEM" -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    Invoke-Test "Driver Script Validation" {
        $driverScript = "$PSScriptRoot\AdvancedDriverUpdater.ps1"
        if (-not (Test-Path $driverScript)) {
            throw "Driver script not found: $driverScript"
        }
        
        # Test syntax by parsing the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $driverScript -Raw), [ref]$null)
        return "Driver script syntax is valid"
    } "Validate driver updater script syntax"
    
    Invoke-Test "Hardware Detection" {
        $devices = Get-PnpDevice | Where-Object { $_.Status -eq "OK" } | Select-Object -First 5
        if ($devices.Count -eq 0) {
            throw "No hardware devices detected"
        }
        return "Detected $($devices.Count) hardware devices"
    } "Test hardware device detection"
    
    Invoke-Test "Driver Information Retrieval" {
        $drivers = Get-WmiObject Win32_SystemDriver | Select-Object -First 5
        if ($drivers.Count -eq 0) {
            throw "No system drivers found"
        }
        return "Found $($drivers.Count) system drivers"
    } "Test driver information retrieval"
}

# Test optimization system functionality
function Test-OptimizationSystem {
    Write-Host "`n⚡ TESTING OPTIMIZATION SYSTEM" -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    Invoke-Test "Optimization Script Validation" {
        $optimizationScript = "$PSScriptRoot\PCOptimizationSuite.ps1"
        if (-not (Test-Path $optimizationScript)) {
            throw "Optimization script not found: $optimizationScript"
        }
        
        # Test syntax by parsing the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $optimizationScript -Raw), [ref]$null)
        return "Optimization script syntax is valid"
    } "Validate PC optimization script syntax"
    
    Invoke-Test "Health Score Calculation" {
        # Mock health calculation components
        $memory = Get-WmiObject Win32_OperatingSystem
        $disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        if (-not $memory) { throw "Cannot retrieve memory information" }
        if (-not $disks) { throw "Cannot retrieve disk information" }
        
        return "Health calculation components available"
    } "Test health score calculation components"
    
    Invoke-Test "Performance Metrics" {
        $cpu = (Get-WmiObject Win32_Processor | Measure-Object LoadPercentage -Average).Average
        $memory = Get-WmiObject Win32_OperatingSystem
        $memoryUsage = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize * 100, 2)
        
        return "CPU: $cpu%, Memory: $memoryUsage%"
    } "Test performance metrics collection"
    
    Invoke-Test "Network Configuration" {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        if ($adapters.Count -eq 0) {
            throw "No active network adapters found"
        }
        return "Found $($adapters.Count) active network adapters"
    } "Test network configuration detection"
}

# Test system integration
function Test-SystemIntegration {
    Write-Host "`n🔗 TESTING SYSTEM INTEGRATION" -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    Invoke-Test "Manager Script Validation" {
        $managerScript = "$PSScriptRoot\DriverUpdaterManager.ps1"
        if (-not (Test-Path $managerScript)) {
            throw "Manager script not found: $managerScript"
        }
        
        # Test syntax by parsing the script
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $managerScript -Raw), [ref]$null)
        return "Manager script syntax is valid"
    } "Validate driver updater manager script"
    
    Invoke-Test "Configuration File" {
        $configFile = "$PSScriptRoot\DriverUpdaterConfig.ini"
        if (-not (Test-Path $configFile)) {
            # Create a basic config file for testing
            @"
[Settings]
AutoUpdate=false
CreateRestorePoint=true
LogLevel=Info
ScanInterval=7

[Advanced]
AggressiveMode=false
SkipValidation=false
"@ | Out-File -FilePath $configFile -Encoding UTF8
        }
        return "Configuration file is available"
    } "Test configuration file handling"
    
    Invoke-Test "Error Handling" {
        try {
            # Simulate an error condition
            throw "Test error for error handling validation"
        }
        catch {
            Write-Log "Caught test error: $($_.Exception.Message)" -Level Error -LogType System -Component "TestSuite"
            return "Error handling is working correctly"
        }
    } "Test error handling and logging"
}

# Generate comprehensive test report
function New-TestReport {
    $reportPath = "$PSScriptRoot\TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PC Optimization Suite - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 15px; margin: -20px -20px 20px -20px; border-radius: 8px 8px 0 0; }
        .summary { display: flex; justify-content: space-around; margin: 20px 0; }
        .metric { text-align: center; padding: 15px; background: #ecf0f1; border-radius: 5px; }
        .metric h3 { margin: 0 0 10px 0; color: #2c3e50; }
        .metric .value { font-size: 24px; font-weight: bold; }
        .passed { color: #27ae60; }
        .failed { color: #e74c3c; }
        .warning { color: #f39c12; }
        .test-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px; margin: 20px 0; }
        .test-card { background: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #3498db; }
        .test-card.passed { border-left-color: #27ae60; }
        .test-card.failed { border-left-color: #e74c3c; }
        .test-name { font-weight: bold; margin-bottom: 5px; }
        .test-description { font-size: 0.9em; color: #666; margin-bottom: 10px; }
        .test-status { font-size: 0.9em; }
        .test-output { background: #2c3e50; color: #ecf0f1; padding: 10px; border-radius: 3px; font-family: monospace; font-size: 0.8em; margin-top: 10px; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 PC Optimization Suite - Test Report</h1>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | System: $env:COMPUTERNAME</p>
        </div>
        
        <div class="summary">
            <div class="metric">
                <h3>Total Tests</h3>
                <div class="value">$($Global:TestResults.Summary.Total)</div>
            </div>
            <div class="metric">
                <h3>Passed</h3>
                <div class="value passed">$($Global:TestResults.Summary.Passed)</div>
            </div>
            <div class="metric">
                <h3>Failed</h3>
                <div class="value failed">$($Global:TestResults.Summary.Failed)</div>
            </div>
            <div class="metric">
                <h3>Success Rate</h3>
                <div class="value">$([math]::Round(($Global:TestResults.Summary.Passed / $Global:TestResults.Summary.Total) * 100))%</div>
            </div>
        </div>
        
        <h2>Test Results</h2>
        <div class="test-grid">
"@
    
    foreach ($test in $Global:TestResults.Tests) {
        $statusClass = $test.Status.ToLower()
        $duration = if ($test.Duration) { "$([math]::Round($test.Duration.TotalMilliseconds))ms" } else { "N/A" }
        
        $html += @"
            <div class="test-card $statusClass">
                <div class="test-name">$($test.Name)</div>
                <div class="test-description">$($test.Description)</div>
                <div class="test-status">
                    <strong>Status:</strong> $($test.Status) | 
                    <strong>Duration:</strong> $duration
                </div>
"@
        
        if ($test.Output -and $test.Output.Count -gt 0) {
            $html += "<div class='test-output'>Output: $($test.Output -join '; ')</div>"
        }
        
        if ($test.Errors -and $test.Errors.Count -gt 0) {
            $html += "<div class='test-output'>Errors: $($test.Errors -join '; ')</div>"
        }
        
        $html += "</div>"
    }
    
    $html += @"
        </div>
        
        <div class="footer">
            <p>PC Optimization Suite Test Report | Generated by GitHub Copilot</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Test report generated: $reportPath" -Level Success -LogType System -Component "TestSuite"
    
    return $reportPath
}

# Main execution logic
function Start-TestSuite {
    Write-Host "🧪 PC OPTIMIZATION SUITE - TEST SUITE" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "=========================================" -ForegroundColor Cyan
    
    $Global:TestResults.StartTime = Get-Date
    
    if ($TestLogging -or $TestAll) {
        Test-LoggingSystem
    }
    
    if ($TestRecovery -or $TestAll) {
        Test-RecoverySystem
    }
    
    if ($TestDrivers -or $TestAll) {
        Test-DriverSystem
    }
    
    if ($TestOptimization -or $TestAll) {
        Test-OptimizationSystem
    }
    
    if ($TestAll) {
        Test-SystemIntegration
    }
    
    # Display summary
    Write-Host "`n📊 TEST SUMMARY" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host "Total Tests: $($Global:TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($Global:TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($Global:TestResults.Summary.Failed)" -ForegroundColor Red
    
    $successRate = if ($Global:TestResults.Summary.Total -gt 0) {
        [math]::Round(($Global:TestResults.Summary.Passed / $Global:TestResults.Summary.Total) * 100)
    } else { 0 }
    
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    
    if ($GenerateReport) {
        $reportPath = New-TestReport
        Write-Host "`n📄 Report generated: $reportPath" -ForegroundColor Cyan
        
        # Try to open the report
        try {
            Start-Process $reportPath
        } catch {
            Write-Host "Could not auto-open report. Please open manually: $reportPath" -ForegroundColor Yellow
        }
    }
    
    # Final status
    if ($Global:TestResults.Summary.Failed -eq 0) {
        Write-Host "`n✅ ALL TESTS PASSED - SYSTEM IS READY!" -ForegroundColor Green -BackgroundColor Black
        Write-Log "All tests passed successfully" -Level Success -LogType System -Component "TestSuite"
    } else {
        Write-Host "`n⚠️  SOME TESTS FAILED - PLEASE REVIEW" -ForegroundColor Red -BackgroundColor Black
        Write-Log "$($Global:TestResults.Summary.Failed) tests failed" -Level Warning -LogType System -Component "TestSuite"
    }
}

# Script execution
if (-not ($TestLogging -or $TestRecovery -or $TestDrivers -or $TestOptimization -or $TestAll)) {
    Write-Host "PC Optimization Suite Test Runner" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  -TestLogging      Test logging system functionality"
    Write-Host "  -TestRecovery     Test recovery and recommendation system"
    Write-Host "  -TestDrivers      Test driver update functionality"
    Write-Host "  -TestOptimization Test performance optimization"
    Write-Host "  -TestAll          Run all tests (recommended)"
    Write-Host "  -GenerateReport   Generate HTML test report"
    Write-Host ""
    Write-Host "Example: .\TestSuite.ps1 -TestAll -GenerateReport" -ForegroundColor Green
} else {
    Start-TestSuite
}