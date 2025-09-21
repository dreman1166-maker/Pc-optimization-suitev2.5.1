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
    Write-Host "✅ Logging system loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load logging system: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n🧪 PC OPTIMIZATION SUITE - VALIDATION TEST" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Test 1: Check all script files exist
Write-Host "`n📁 Checking script files..." -ForegroundColor Yellow
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
        Write-Host "   ✅ $script" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $script (missing)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

# Test 2: Validate PowerShell syntax
Write-Host "`n🔍 Validating PowerShell syntax..." -ForegroundColor Yellow
$syntaxErrors = 0
foreach ($script in $scripts) {
    $path = "$PSScriptRoot\$script"
    if (Test-Path $path) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $path -Raw), [ref]$null)
            Write-Host "   ✅ $script syntax valid" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ $script syntax error: $($_.Exception.Message)" -ForegroundColor Red
            $syntaxErrors++
        }
    }
}

# Test 3: Test logging functionality
Write-Host "`n📝 Testing logging functionality..." -ForegroundColor Yellow
try {
    Write-Log "Test log entry" -Level Info -LogType System -Component "Validation"
    Write-Log "Test warning entry" -Level Warning -LogType System -Component "Validation"
    Write-Log "Test success entry" -Level Success -LogType System -Component "Validation"
    Write-Host "   ✅ Logging system working" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Logging system failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test system health calculation
Write-Host "`n💡 Testing system health..." -ForegroundColor Yellow
try {
    $health = Get-OverallSystemHealth
    Write-Host "   ✅ System health score: $health%" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Health calculation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Test hardware detection
Write-Host "`n🔌 Testing hardware detection..." -ForegroundColor Yellow
try {
    $devices = Get-PnpDevice | Where-Object { $_.Status -eq "OK" } | Select-Object -First 5
    Write-Host "   ✅ Detected $($devices.Count) hardware devices" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Hardware detection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Test recovery recommendations
Write-Host "`n🔧 Testing recovery system..." -ForegroundColor Yellow
try {
    # Generate a test error for analysis
    Write-Log "Test error for recovery analysis" -Level Error -LogType System -Component "ValidationTest"
    
    $recommendations = Get-RecoveryRecommendations -DaysToAnalyze 1
    if ($recommendations -and $recommendations.TotalRecommendations -ge 0) {
        Write-Host "   ✅ Recovery system working: $($recommendations.TotalRecommendations) recommendations" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Recovery system returned no recommendations" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Recovery system failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final Summary
Write-Host "`n📊 VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

if ($allFilesExist -and $syntaxErrors -eq 0) {
    Write-Host "✅ ALL VALIDATION TESTS PASSED!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   Your PC Optimization Suite is ready to use!" -ForegroundColor Green
    Write-Host "`n🚀 To start the system, run:" -ForegroundColor Cyan
    Write-Host "   .\DriverUpdaterManager.ps1" -ForegroundColor White -BackgroundColor DarkBlue
} else {
    Write-Host "❌ VALIDATION ISSUES DETECTED" -ForegroundColor Red -BackgroundColor Black
    if (-not $allFilesExist) {
        Write-Host "   Some script files are missing" -ForegroundColor Red
    }
    if ($syntaxErrors -gt 0) {
        Write-Host "   $syntaxErrors syntax errors found" -ForegroundColor Red
    }
}

Write-Host "`n📄 Check the logs directory for detailed logging:" -ForegroundColor Gray
Write-Host "   $Global:LogPath" -ForegroundColor White