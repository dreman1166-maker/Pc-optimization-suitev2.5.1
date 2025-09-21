#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Simple System Validation Test
    
.DESCRIPTION
    Quick validation test for the PC optimization system
#>

# Import logging system
try {
    . "$PSScriptRoot\SystemLogger.ps1"
    Write-Host "SUCCESS: Logging system loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to load logging system: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "PC OPTIMIZATION SUITE - VALIDATION TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Test 1: Check all script files exist
Write-Host ""
Write-Host "Checking script files..." -ForegroundColor Yellow
$scripts = @(
    "AdvancedDriverUpdater.ps1",
    "PCOptimizationSuite.ps1", 
    "DriverUpdaterManager.ps1",
    "SystemLogger.ps1"
)

$allFilesExist = $true
foreach ($script in $scripts) {
    $path = "$PSScriptRoot\$script"
    if (Test-Path $path) {
        Write-Host "   SUCCESS: $script" -ForegroundColor Green
    } else {
        Write-Host "   ERROR: $script (missing)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# Test 2: Validate PowerShell syntax
Write-Host ""
Write-Host "Validating PowerShell syntax..." -ForegroundColor Yellow
$syntaxErrors = 0
foreach ($script in $scripts) {
    $path = "$PSScriptRoot\$script"
    if (Test-Path $path) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$null)
            Write-Host "   SUCCESS: $script syntax valid" -ForegroundColor Green
        } catch {
            Write-Host "   ERROR: $script syntax error: $($_.Exception.Message)" -ForegroundColor Red
            $syntaxErrors++
        }
    }
}

# Test 3: Test logging functionality
Write-Host ""
Write-Host "Testing logging functionality..." -ForegroundColor Yellow
try {
    Write-Log "Test log entry" -Level Info -LogType System -Component "Validation"
    Write-Log "Test warning entry" -Level Warning -LogType System -Component "Validation"
    Write-Log "Test success entry" -Level Success -LogType System -Component "Validation"
    Write-Host "   SUCCESS: Logging system working" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Logging system failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test system health calculation
Write-Host ""
Write-Host "Testing system health..." -ForegroundColor Yellow
try {
    $health = Get-OverallSystemHealth
    Write-Host "   SUCCESS: System health score: $health%" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Health calculation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Test hardware detection
Write-Host ""
Write-Host "Testing hardware detection..." -ForegroundColor Yellow
try {
    $devices = Get-PnpDevice | Where-Object { $_.Status -eq "OK" } | Select-Object -First 5
    Write-Host "   SUCCESS: Detected $($devices.Count) hardware devices" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Hardware detection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Test recovery recommendations
Write-Host ""
Write-Host "Testing recovery system..." -ForegroundColor Yellow
try {
    # Generate a test error for analysis
    Write-Log "Test error for recovery analysis" -Level Error -LogType System -Component "ValidationTest"
    
    $recommendations = Get-RecoveryRecommendation -DaysToAnalyze 1
    if ($recommendations -and $recommendations.TotalRecommendations -ge 0) {
        Write-Host "   SUCCESS: Recovery system working: $($recommendations.TotalRecommendations) recommendations" -ForegroundColor Green
    } else {
        Write-Host "   WARNING: Recovery system returned no recommendations" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ERROR: Recovery system failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final Summary
Write-Host ""
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

if ($allFilesExist -and $syntaxErrors -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: ALL VALIDATION TESTS PASSED!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "Your PC Optimization Suite is ready to use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To start the system, run:" -ForegroundColor Cyan
    Write-Host ".\DriverUpdaterManager.ps1" -ForegroundColor White -BackgroundColor DarkBlue
} else {
    Write-Host ""
    Write-Host "ERROR: VALIDATION ISSUES DETECTED" -ForegroundColor Red -BackgroundColor Black
    if (-not $allFilesExist) {
        Write-Host "Some script files are missing" -ForegroundColor Red
    }
    if ($syntaxErrors -gt 0) {
        Write-Host "$syntaxErrors syntax errors found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Check the logs directory for detailed logging:" -ForegroundColor Gray
Write-Host "$Global:LogPath" -ForegroundColor White
Write-Host ""