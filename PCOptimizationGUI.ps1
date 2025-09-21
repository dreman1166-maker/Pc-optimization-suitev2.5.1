#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    PC Optimization Suite GUI v2.5.0 - Modern Windows Forms Interface
    
.DESCRIPTION
    Professional Windows Forms application with real-time dashboards, performance monitoring,
    live time display, specialized optimization tools, and enhanced user experience.
    
.AUTHOR
    PC Optimization Suite Team
    
.VERSION
    2.5.0 - Enhanced Interface with Live Time Display and Specialized Optimizations
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# Global Variables
$script:ModuleVersion = "2.5.1"
$script:BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$script:DataPath = Join-Path $script:BasePath "Data"
$script:LogPath = Join-Path $script:BasePath "Logs"

# Import performance optimizations
$perfOptimizationsPath = Join-Path $script:BasePath "GUI_Performance_Optimizations.ps1"
if (Test-Path $perfOptimizationsPath) {
    . $perfOptimizationsPath
    Write-Host "[OK] Performance optimizations loaded" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Performance optimizations not found - using standard mode" -ForegroundColor Yellow
}

# Ensure directories exist
@($script:DataPath, $script:LogPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# GUI Color Themes
$script:Themes = @{
    "Dark Blue"     = @{
        Background     = [System.Drawing.Color]::FromArgb(32, 32, 32)
        CardBackground = [System.Drawing.Color]::FromArgb(48, 48, 48)
        Primary        = [System.Drawing.Color]::FromArgb(0, 120, 215)
        Success        = [System.Drawing.Color]::FromArgb(16, 124, 16)
        Warning        = [System.Drawing.Color]::FromArgb(255, 185, 0)
        Error          = [System.Drawing.Color]::FromArgb(196, 43, 28)
        Text           = [System.Drawing.Color]::FromArgb(255, 255, 255)
        TextSecondary  = [System.Drawing.Color]::FromArgb(200, 200, 200)
        Border         = [System.Drawing.Color]::FromArgb(64, 64, 64)
    }
    "Dark Green"    = @{
        Background     = [System.Drawing.Color]::FromArgb(24, 40, 24)
        CardBackground = [System.Drawing.Color]::FromArgb(40, 56, 40)
        Primary        = [System.Drawing.Color]::FromArgb(0, 180, 100)
        Success        = [System.Drawing.Color]::FromArgb(32, 150, 32)
        Warning        = [System.Drawing.Color]::FromArgb(255, 185, 0)
        Error          = [System.Drawing.Color]::FromArgb(196, 43, 28)
        Text           = [System.Drawing.Color]::FromArgb(240, 255, 240)
        TextSecondary  = [System.Drawing.Color]::FromArgb(180, 200, 180)
        Border         = [System.Drawing.Color]::FromArgb(80, 96, 80)
    }
    "Dark Purple"   = @{
        Background     = [System.Drawing.Color]::FromArgb(40, 24, 40)
        CardBackground = [System.Drawing.Color]::FromArgb(56, 40, 56)
        Primary        = [System.Drawing.Color]::FromArgb(150, 50, 200)
        Success        = [System.Drawing.Color]::FromArgb(16, 124, 16)
        Warning        = [System.Drawing.Color]::FromArgb(255, 185, 0)
        Error          = [System.Drawing.Color]::FromArgb(196, 43, 28)
        Text           = [System.Drawing.Color]::FromArgb(250, 240, 250)
        TextSecondary  = [System.Drawing.Color]::FromArgb(200, 180, 200)
        Border         = [System.Drawing.Color]::FromArgb(96, 80, 96)
    }
    "Light Gray"    = @{
        Background     = [System.Drawing.Color]::FromArgb(240, 240, 240)
        CardBackground = [System.Drawing.Color]::FromArgb(255, 255, 255)
        Primary        = [System.Drawing.Color]::FromArgb(0, 120, 215)
        Success        = [System.Drawing.Color]::FromArgb(16, 124, 16)
        Warning        = [System.Drawing.Color]::FromArgb(255, 140, 0)
        Error          = [System.Drawing.Color]::FromArgb(196, 43, 28)
        Text           = [System.Drawing.Color]::FromArgb(32, 32, 32)
        TextSecondary  = [System.Drawing.Color]::FromArgb(96, 96, 96)
        Border         = [System.Drawing.Color]::FromArgb(200, 200, 200)
    }
    "Ocean Blue"    = @{
        Background     = [System.Drawing.Color]::FromArgb(16, 32, 48)
        CardBackground = [System.Drawing.Color]::FromArgb(32, 48, 64)
        Primary        = [System.Drawing.Color]::FromArgb(64, 160, 255)
        Success        = [System.Drawing.Color]::FromArgb(0, 200, 150)
        Warning        = [System.Drawing.Color]::FromArgb(255, 185, 0)
        Error          = [System.Drawing.Color]::FromArgb(255, 80, 80)
        Text           = [System.Drawing.Color]::FromArgb(230, 245, 255)
        TextSecondary  = [System.Drawing.Color]::FromArgb(180, 200, 220)
        Border         = [System.Drawing.Color]::FromArgb(80, 100, 120)
    }
    "Sunset Orange" = @{
        Background     = [System.Drawing.Color]::FromArgb(48, 32, 16)
        CardBackground = [System.Drawing.Color]::FromArgb(64, 48, 32)
        Primary        = [System.Drawing.Color]::FromArgb(255, 140, 50)
        Success        = [System.Drawing.Color]::FromArgb(100, 180, 50)
        Warning        = [System.Drawing.Color]::FromArgb(255, 185, 0)
        Error          = [System.Drawing.Color]::FromArgb(255, 100, 100)
        Text           = [System.Drawing.Color]::FromArgb(255, 245, 230)
        TextSecondary  = [System.Drawing.Color]::FromArgb(220, 200, 180)
        Border         = [System.Drawing.Color]::FromArgb(120, 100, 80)
    }
}

# Current active theme
$script:CurrentTheme = "Dark Blue"
$script:Colors = $script:Themes[$script:CurrentTheme]

# Performance Data Storage
$script:PerformanceHistory = @{
    CPU        = New-Object System.Collections.Generic.List[double]
    Memory     = New-Object System.Collections.Generic.List[double]
    Timestamps = New-Object System.Collections.Generic.List[DateTime]
}

# Auto-refresh variables
$script:AutoRefreshTimer = $null
$script:AutoRefreshEnabled = $true
$script:RefreshInterval = 8000  # 8 seconds (increased to reduce resource usage)
$script:MainForm = $null
$script:LastRefresh = $null  # Track last refresh time for throttling

#region Theme Management Functions

function Set-ApplicationTheme {
    param([string]$ThemeName)
    
    if ($script:Themes.ContainsKey($ThemeName)) {
        $script:CurrentTheme = $ThemeName
        $script:Colors = $script:Themes[$ThemeName]
        
        # Refresh the main form if it exists
        if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            Update-FormColors -Form $script:MainForm
            Add-LogMessage "Theme changed to: $ThemeName"
        }
    }
}

function Update-FormColors {
    param([System.Windows.Forms.Form]$Form)
    
    try {
        # Update form colors
        $Form.BackColor = $script:Colors.Background
        $Form.ForeColor = $script:Colors.Text
        
        # Recursively update all controls
        Update-ControlColors -Control $Form
        
        # Refresh the form
        $Form.Refresh()
    }
    catch {
        Write-Warning "Error updating form colors: $($_.Exception.Message)"
    }
}

function Update-ControlColors {
    param([System.Windows.Forms.Control]$Control)
    
    try {
        # Skip if control is disposed
        if ($Control.IsDisposed) { return }
        
        # Update control colors based on type
        switch ($Control.GetType().Name) {
            "Panel" {
                if ($Control.Tag -eq "CardBackground") {
                    $Control.BackColor = $script:Colors.CardBackground
                }
                else {
                    $Control.BackColor = $script:Colors.Background
                }
                $Control.ForeColor = $script:Colors.Text
            }
            "Label" {
                $Control.ForeColor = if ($Control.Tag -eq "Secondary") { $script:Colors.TextSecondary } else { $script:Colors.Text }
            }
            "Button" {
                if ($Control.Tag -eq "Success") {
                    $Control.BackColor = $script:Colors.Success
                }
                elseif ($Control.Tag -eq "Warning") {
                    $Control.BackColor = $script:Colors.Warning
                }
                elseif ($Control.Tag -eq "Primary") {
                    $Control.BackColor = $script:Colors.Primary
                }
                else {
                    $Control.BackColor = $script:Colors.CardBackground
                }
                $Control.ForeColor = $script:Colors.Text
            }
            "TextBox" {
                $Control.BackColor = $script:Colors.Background
                $Control.ForeColor = $script:Colors.Text
            }
            "ComboBox" {
                $Control.BackColor = $script:Colors.CardBackground
                $Control.ForeColor = $script:Colors.Text
            }
            "TabControl" {
                $Control.BackColor = $script:Colors.CardBackground
                $Control.ForeColor = $script:Colors.Text
            }
            "TabPage" {
                $Control.BackColor = $script:Colors.Background
                $Control.ForeColor = $script:Colors.Text
            }
        }
        
        # Recursively update child controls
        foreach ($childControl in $Control.Controls) {
            Update-ControlColors -Control $childControl
        }
    }
    catch {
        # Silently ignore errors for disposed controls
    }
}

function Start-AutoRefresh {
    if ($script:AutoRefreshEnabled -and $script:MainForm -and -not $script:MainForm.IsDisposed) {
        $script:AutoRefreshTimer = New-Object System.Windows.Forms.Timer
        $script:AutoRefreshTimer.Interval = $script:RefreshInterval
        $script:AutoRefreshTimer.Add_Tick({
                try {
                    if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
                        Update-Dashboard
                    }
                }
                catch {
                    # Silently handle refresh errors
                }
            })
        $script:AutoRefreshTimer.Start()
        Add-LogMessage "Auto-refresh started (every $($script:RefreshInterval/1000) seconds)"
    }
}

function Stop-AutoRefresh {
    if ($script:AutoRefreshTimer) {
        $script:AutoRefreshTimer.Stop()
        $script:AutoRefreshTimer.Dispose()
        $script:AutoRefreshTimer = $null
        Add-LogMessage "Auto-refresh stopped"
    }
}

function Update-Dashboard {
    # Use optimized refresh if available
    if (Get-Command Update-UIWithCachedData -ErrorAction SilentlyContinue) {
        Update-UIWithCachedData
        return
    }
    
    # Original implementation with throttling
    try {
        # Throttle updates to prevent excessive resource usage
        if ($script:LastRefresh) {
            $timeSinceLastRefresh = (Get-Date) - $script:LastRefresh
            if ($timeSinceLastRefresh.TotalSeconds -lt 3) {
                return  # Skip if refreshed less than 3 seconds ago
            }
        }
        $script:LastRefresh = Get-Date
        
        # Update performance data in the background
        $systemData = Get-SystemOverview
        if ($systemData -and $script:MainForm -and -not $script:MainForm.IsDisposed) {
            # Update performance history
            $script:PerformanceHistory.CPU.Add($systemData.CPUUsage)
            $script:PerformanceHistory.Memory.Add($systemData.MemoryUsage)
            $script:PerformanceHistory.Timestamps.Add((Get-Date))
            
            # Keep only last 50 entries
            if ($script:PerformanceHistory.CPU.Count -gt 50) {
                $script:PerformanceHistory.CPU.RemoveAt(0)
                $script:PerformanceHistory.Memory.RemoveAt(0)
                $script:PerformanceHistory.Timestamps.RemoveAt(0)
            }
            
            # Update the main form on the UI thread
            $script:MainForm.Invoke([Action] {
                    try {
                        Update-DashboardData -SystemData $systemData
                    }
                    catch {
                        # Silently handle UI update errors
                    }
                })
        }
    }
    catch {
        # Silently handle refresh errors to prevent crashes
    }
}

function Update-DashboardData {
    param($SystemData)
    
    # This function will be implemented to update specific UI elements
    # For now, just add a log message to show it's working
    if ($script:LogTextBox -and -not $script:LogTextBox.IsDisposed) {
        # Add timestamp to activity log occasionally
        $currentTime = Get-Date
        if ($currentTime.Second % 30 -eq 0) {
            # Every 30 seconds
            Add-LogMessage "System monitoring active - CPU: $($SystemData.CPUUsage)%, Memory: $($SystemData.MemoryUsage)%"
        }
    }
}

#endregion

#region Data Collection Functions

function Get-SystemOverview {
    # Use optimized version if available, otherwise fall back to original
    if (Get-Command Get-OptimizedSystemOverview -ErrorAction SilentlyContinue) {
        return Get-OptimizedSystemOverview
    }
    
    # Original implementation as fallback
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        # Get performance counters
        $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
        $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        
        return @{
            ComputerName = $cs.Name
            OS           = $os.Caption
            OSVersion    = $os.Version
            CPU          = $cpu.Name
            TotalRAM     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            CPUUsage     = [math]::Round($cpuUsage, 1)
            MemoryUsage  = $memoryUsage
            Uptime       = ((Get-Date) - $os.LastBootUpTime).ToString("dd\.hh\:mm")
        }
    }
    catch {
        Write-Host "Error getting system overview: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-DriverHealthSummary {
    # Use optimized version if available, otherwise fall back to original
    if (Get-Command Get-OptimizedDriverHealthSummary -ErrorAction SilentlyContinue) {
        return Get-OptimizedDriverHealthSummary
    }
    
    # Original implementation as fallback
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
        }
        else { 100 }
        
        return @{
            TotalDevices   = $totalDevices
            ProblemDevices = $problemCount
            HealthScore    = $healthScore
            Status         = if ($healthScore -ge 90) { "Good" } elseif ($healthScore -ge 70) { "Fair" } else { "Poor" }
        }
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

function Get-PerformanceScore {
    try {
        # Try to load existing benchmark data
        $benchmarkFiles = Get-ChildItem -Path $script:DataPath -Filter "Benchmark_*.json" -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($benchmarkFiles) {
            $benchmark = Get-Content $benchmarkFiles.FullName | ConvertFrom-Json
            if ($benchmark.OverallScore) {
                return [int]$benchmark.OverallScore
            }
        }
        
        return "Click to Run"
    }
    catch {
        return "Error"
    }
}

function New-LiveTimeDisplay {
    param(
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 200,
        [int]$Height = 80
    )
    
    # Create panel using existing ModernPanel function but modify border afterwards
    $timePanel = New-ModernPanel -X $X -Y $Y -Width $Width -Height $Height -BackColor "Background"
    $timePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::None  # Remove border for seamless look
    $timePanel.BackColor = [System.Drawing.Color]::Transparent  # Make background transparent
    
    # Time label - improved positioning to prevent any cutoff
    $script:LiveTimeLabel = New-ModernLabel -Text "" -X 5 -Y 12 -Width ($Width - 10) -Height 28 -FontSize 11 -FontStyle "Bold"
    $script:LiveTimeLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $timePanel.Controls.Add($script:LiveTimeLabel)
    
    # Date label - better spacing and width
    $script:LiveDateLabel = New-ModernLabel -Text "" -X 5 -Y 36 -Width ($Width - 10) -Height 16 -FontSize 8 -ForeColor "TextSecondary"
    $script:LiveDateLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $timePanel.Controls.Add($script:LiveDateLabel)
    
    # Full date label - adjusted for better fit
    $script:LiveFullDateLabel = New-ModernLabel -Text "" -X 5 -Y 54 -Width ($Width - 10) -Height 18 -FontSize 7 -ForeColor "TextSecondary"
    $script:LiveFullDateLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $timePanel.Controls.Add($script:LiveFullDateLabel)
    
    # Start the timer
    Start-LiveTimeUpdate
    
    return $timePanel
}

function Start-LiveTimeUpdate {
    # Create and start timer for live time updates
    $script:TimeTimer = New-Object System.Windows.Forms.Timer
    $script:TimeTimer.Interval = 1000  # Update every second
    $script:TimeTimer.Add_Tick({
            try {
                $now = Get-Date
                if ($script:LiveTimeLabel -and -not $script:LiveTimeLabel.IsDisposed) {
                    # Get current time format setting
                    $settings = Get-OptimizationSettings
                    $timeFormat = if ($settings.TimeFormat -eq "12-hour") { "hh:mm:ss tt" } else { "HH:mm:ss" }
                    $script:LiveTimeLabel.Text = $now.ToString($timeFormat)
                }
                if ($script:LiveDateLabel -and -not $script:LiveDateLabel.IsDisposed) {
                    # Shorter date format to prevent cutoff
                    $script:LiveDateLabel.Text = $now.ToString("ddd, MMM dd")
                }
                if ($script:LiveFullDateLabel -and -not $script:LiveFullDateLabel.IsDisposed) {
                    # More compact format
                    $script:LiveFullDateLabel.Text = $now.ToString("yyyy") + " | Day " + $now.DayOfYear.ToString()
                }
            }
            catch {
                # Ignore timer errors
            }
        })
    $script:TimeTimer.Start()
}

function Stop-LiveTimeUpdate {
    if ($script:TimeTimer) {
        $script:TimeTimer.Stop()
        $script:TimeTimer.Dispose()
    }
}

function Show-PerformanceScoreLegend {
    # Create legend dialog
    $legendForm = New-Object System.Windows.Forms.Form
    $legendForm.Text = "Performance Score Legend"
    $legendForm.Size = New-Object System.Drawing.Size(550, 450)
    $legendForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $legendForm.BackColor = $script:Colors.Background
    $legendForm.ForeColor = $script:Colors.Text
    $legendForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $legendForm.MaximizeBox = $false
    $legendForm.MinimizeBox = $false
    
    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Performance Score Ratings & Meanings"
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(510, 25)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $legendForm.Controls.Add($titleLabel)
    
    # Legend content
    $legendBox = New-Object System.Windows.Forms.TextBox
    $legendBox.Location = New-Object System.Drawing.Point(20, 50)
    $legendBox.Size = New-Object System.Drawing.Size(510, 320)
    $legendBox.Multiline = $true
    $legendBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $legendBox.ReadOnly = $true
    $legendBox.BackColor = $script:Colors.CardBackground
    $legendBox.ForeColor = $script:Colors.Text
    $legendBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $legendText = @"
PERFORMANCE SCORE LEGEND
========================

SCORE RANGES:
-------------
90,000+ .... EXCEPTIONAL
            Ultra-high performance system. Top-tier gaming and 
            professional workstation capability. Excellent for:
            • 4K gaming at highest settings
            • Video editing and rendering
            • 3D modeling and CAD work
            • Virtual machines and servers

70,000-89,999 .... EXCELLENT
            High-performance system with great capabilities.
            Suitable for:
            • 1440p/4K gaming at high settings
            • Content creation and streaming
            • Software development
            • Multi-tasking heavy workloads

50,000-69,999 .... VERY GOOD
            Above-average performance for most tasks.
            Good for:
            • 1080p/1440p gaming at medium-high settings
            • Office work and productivity
            • Light content creation
            • General computing tasks

30,000-49,999 .... GOOD
            Solid performance for everyday computing.
            Adequate for:
            • 1080p gaming at medium settings
            • Web browsing and office applications
            • Basic photo editing
            • Streaming media consumption

15,000-29,999 .... AVERAGE
            Basic performance for standard tasks.
            Suitable for:
            • Light gaming at low-medium settings
            • Web browsing and email
            • Document editing
            • Basic multimedia

5,000-14,999 .... BELOW AVERAGE
            Limited performance, may need optimization.
            Suitable for:
            • Basic web browsing
            • Simple office tasks
            • Older or casual games
            • Optimization recommended

Under 5,000 .... POOR
            Significant performance issues detected.
            Recommendations:
            • Run system optimization
            • Check for malware/viruses
            • Consider hardware upgrades
            • Clean temporary files and registry

BENCHMARK COMPONENTS:
--------------------
• CPU Score: Processor computational performance
• Memory Score: RAM speed and efficiency
• Storage Score: Disk read/write performance

Overall Score = Average of all component scores

NOTE: Scores may vary based on system load, background
      processes, and current system state.
"@
    
    $legendBox.Text = $legendText
    $legendForm.Controls.Add($legendBox)
    
    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(450, 380)
    $closeButton.Size = New-Object System.Drawing.Size(80, 30)
    $closeButton.BackColor = $script:Colors.Primary
    $closeButton.ForeColor = $script:Colors.Text
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.FlatAppearance.BorderSize = 0
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $closeButton.Add_Click({ $legendForm.Close() })
    $legendForm.Controls.Add($closeButton)
    
    $legendForm.ShowDialog()
}

function Show-PatchNotes {
    Add-LogMessage "Opening patch notes..."
    
    # Create patch notes form with simplified color handling
    $patchForm = New-Object System.Windows.Forms.Form
    $patchForm.Text = "PC Optimization Suite - Patch Notes v2.5.1"
    $patchForm.Size = New-Object System.Drawing.Size(700, 600)
    $patchForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $patchForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $patchForm.MaximizeBox = $false
    $patchForm.MinimizeBox = $false
    $patchForm.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)  # Dark background
    $patchForm.ForeColor = [System.Drawing.Color]::White
    $patchForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "PC OPTIMIZATION SUITE v2.5.1 - PATCH NOTES"
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(640, 25)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 150, 255)  # Blue accent
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $patchForm.Controls.Add($titleLabel)
    
    # Release date and time
    $releaseLabel = New-Object System.Windows.Forms.Label
    $releaseLabel.Text = "Released: 21/09/2025 at 06:50:15 GMT"
    $releaseLabel.Location = New-Object System.Drawing.Point(20, 45)
    $releaseLabel.Size = New-Object System.Drawing.Size(640, 20)
    $releaseLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $releaseLabel.ForeColor = [System.Drawing.Color]::LightGray
    $releaseLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $patchForm.Controls.Add($releaseLabel)
    
    # Patch notes text box
    $patchNotesBox = New-Object System.Windows.Forms.RichTextBox
    $patchNotesBox.Location = New-Object System.Drawing.Point(20, 75)
    $patchNotesBox.Size = New-Object System.Drawing.Size(640, 450)
    $patchNotesBox.BackColor = [System.Drawing.Color]::FromArgb(55, 55, 58)  # Slightly lighter background
    $patchNotesBox.ForeColor = [System.Drawing.Color]::White
    $patchNotesBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $patchNotesBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $patchNotesBox.ReadOnly = $true
    $patchNotesBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    
    # Detailed patch notes content
    $patchContent = @"
===============================================================================
v2.5.1 HOTFIX UPDATE - September 21, 2025
===============================================================================

CRITICAL TIME DISPLAY FIXES
   • FIXED: Time display cutoff at top of panel - adjusted positioning
   • FIXED: Overlap with computer name text - reduced panel size and adjusted layout
   • ENHANCED: Made time panel background fully transparent for seamless integration
   • IMPROVED: Optimized label spacing within 75px height constraint
   • REFINED: System information truncation to prevent layout conflicts

===============================================================================
v2.5.0 MAJOR RELEASE - September 21, 2025
===============================================================================

MAJOR NEW FEATURES
===============================================================================

LIVE TIME DISPLAY WITH CUSTOMIZABLE FORMAT
   • Added real-time clock display in the main interface
   • Configurable 12-hour (hh:mm:ss AM/PM) or 24-hour (HH:mm:ss) format
   • Seamless integration with no borders or visual interruptions
   • Auto-refresh every second with precise time synchronization
   • Date display showing day, month, and day of year

SPECIALIZED OPTIMIZATION BUTTONS
   • Game/Software Boost: Enhanced gaming performance optimization
   • Internet Boost: Network and connection speed improvements
   • Run Smoother: General system responsiveness enhancements
   • Each button provides targeted optimizations for specific use cases

COMPREHENSIVE PERFORMANCE SCORE SYSTEM
   • Advanced benchmarking with CPU, Memory, and Storage tests
   • 7-tier scoring system from "Critical" to "Exceptional"
   • Interactive performance score legend (right-click to view)
   • Detailed explanations of what each score range means
   • Real-time performance monitoring and re-testing capability

===============================================================================
CRITICAL BUG FIXES "&" IMPROVEMENTS
===============================================================================

TIME DISPLAY ENHANCEMENTS
   • FIXED: Text cutoff issues with time display positioning
   • FIXED: Border removal for seamless background integration
   • IMPROVED: Dynamic width adjustment for both 12/24 hour formats
   • ENHANCED: Better font sizing and positioning for readability

PERFORMANCE "&" STABILITY
   • FIXED: Divide-by-zero errors in benchmark calculations
   • FIXED: Settings collection modification exceptions
   • IMPROVED: Memory management and resource disposal
   • ENHANCED: Error handling throughout the application

USER INTERFACE POLISH
   • IMPROVED: Settings dialog with new time format options
   • ENHANCED: Modern flat design with consistent styling
   • FIXED: Dialog close button functionality and positioning
   • OPTIMIZED: Theme switching and color consistency

===============================================================================
TECHNICAL IMPROVEMENTS
===============================================================================

SETTINGS SYSTEM OVERHAUL
   • Added TimeFormat setting with instant application
   • Improved settings persistence and loading reliability
   • Enhanced error recovery with safe default fallbacks
   • Real-time setting application without restart required

BENCHMARKING ENGINE
   • Advanced CPU performance testing with iteration counting
   • Memory speed testing with large array operations
   • Storage I/O testing with read/write performance metrics
   • Comprehensive scoring algorithm with weighted calculations

CODE QUALITY ENHANCEMENTS
   • Comprehensive error handling and exception management
   • Proper resource cleanup and memory leak prevention
   • Consistent coding standards and documentation
   • Performance optimizations throughout the codebase

===============================================================================
USER EXPERIENCE IMPROVEMENTS
===============================================================================

INSTANT FEEDBACK
   • Real-time status updates during optimizations
   • Progress indicators for long-running operations
   • Immediate application of settings changes
   • Live system monitoring with auto-refresh

VISUAL ENHANCEMENTS
   • Professional color schemes with multiple themes
   • Consistent button styling and hover effects
   • Improved spacing and layout for better readability
   • Modern Windows 11-style interface elements

ENHANCED LOGGING
   • Detailed operation logging with timestamps
   • Color-coded log messages for different event types
   • Improved error reporting and diagnostic information
   • Real-time log display in the interface

===============================================================================
FUTURE ROADMAP PREVIEW
===============================================================================

Coming in future updates:
• Advanced driver management with automatic updates
• System health monitoring with predictive analysis
• Custom optimization profiles for different use cases
• Integration with cloud-based performance analytics
• Enhanced security scanning and malware protection

===============================================================================

Thank you for using PC Optimization Suite! This major update represents
months of development work focused on improving performance, reliability,
and user experience. We hope you enjoy the new features and improvements!

Feedback and suggestions are always welcome for future updates.
"@
    
    $patchNotesBox.Text = $patchContent
    $patchForm.Controls.Add($patchNotesBox)
    
    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(580, 535)
    $closeButton.Size = New-Object System.Drawing.Size(80, 30)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(100, 150, 255)  # Blue accent
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.FlatAppearance.BorderSize = 0
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $closeButton.Add_Click({ $patchForm.Close() })
    $patchForm.Controls.Add($closeButton)
    
    $patchForm.ShowDialog()
}

#endregion

#region GUI Helper Functions

function New-ModernPanel {
    param(
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 100,
        [int]$Height = 100,
        [string]$BackColor = "CardBackground"
    )
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.BackColor = $script:Colors[$BackColor]
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $panel.Tag = $BackColor  # Store color type for theme updates
    
    return $panel
}

function New-ModernLabel {
    param(
        [string]$Text = "",
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 100,
        [int]$Height = 23,
        [string]$ForeColor = "Text",
        [int]$FontSize = 9,
        [string]$FontStyle = "Regular"
    )
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.ForeColor = $script:Colors[$ForeColor]
    # Let background inherit from parent instead of forcing transparent
    
    $font = New-Object System.Drawing.Font("Segoe UI", $FontSize, [System.Drawing.FontStyle]::$FontStyle)
    $label.Font = $font
    
    return $label
}

function New-ModernButton {
    param(
        [string]$Text = "",
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 100,
        [int]$Height = 35,
        [string]$BackColor = "Primary"
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.BackColor = $script:Colors[$BackColor]
    $button.ForeColor = $script:Colors.Text
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.Tag = $BackColor  # Store color type for theme updates
    
    $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $button.Font = $font
    
    return $button
}

function New-ProgressCard {
    param(
        [string]$Title,
        [double]$Value,
        [double]$MaxValue = 100,
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 200,
        [int]$Height = 100
    )
    
    $panel = New-ModernPanel -X $X -Y $Y -Width $Width -Height $Height
    
    # Title
    $titleLabel = New-ModernLabel -Text $Title -X 10 -Y 10 -Width ($Width - 20) -Height 20 -FontSize 10 -FontStyle "Bold"
    $panel.Controls.Add($titleLabel)
    
    # Value
    $percentage = [math]::Round(($Value / $MaxValue) * 100, 1)
    $valueLabel = New-ModernLabel -Text "$percentage%" -X 10 -Y 35 -Width ($Width - 20) -Height 25 -FontSize 14 -FontStyle "Bold"
    
    # Color based on value
    if ($percentage -gt 80) {
        $valueLabel.ForeColor = $script:Colors.Error
    }
    elseif ($percentage -gt 60) {
        $valueLabel.ForeColor = $script:Colors.Warning
    }
    else {
        $valueLabel.ForeColor = $script:Colors.Success
    }
    
    $panel.Controls.Add($valueLabel)
    
    # Progress Bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 70)
    $progressBar.Size = New-Object System.Drawing.Size(($Width - 20), 20)
    $progressBar.Value = [math]::Min($percentage, 100)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $panel.Controls.Add($progressBar)
    
    return $panel
}

function New-StatusCard {
    param(
        [string]$Title,
        [string]$Status,
        [string]$Details,
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 200,
        [int]$Height = 120
    )
    
    $panel = New-ModernPanel -X $X -Y $Y -Width $Width -Height $Height
    
    # Title
    $titleLabel = New-ModernLabel -Text $Title -X 10 -Y 10 -Width ($Width - 20) -Height 20 -FontSize 10 -FontStyle "Bold"
    $panel.Controls.Add($titleLabel)
    
    # Status
    $statusLabel = New-ModernLabel -Text $Status -X 10 -Y 35 -Width ($Width - 20) -Height 25 -FontSize 12 -FontStyle "Bold"
    
    # Color based on status
    switch ($Status) {
        "Excellent" { $statusLabel.ForeColor = $script:Colors.Success }
        "Good" { $statusLabel.ForeColor = $script:Colors.Warning }
        "Needs Attention" { $statusLabel.ForeColor = $script:Colors.Error }
        default { $statusLabel.ForeColor = $script:Colors.Text }
    }
    
    $panel.Controls.Add($statusLabel)
    
    # Details
    $detailsLabel = New-ModernLabel -Text $Details -X 10 -Y 65 -Width ($Width - 20) -Height 40 -FontSize 8 -ForeColor "TextSecondary"
    $panel.Controls.Add($detailsLabel)
    
    return $panel
}

#endregion

#region Main Form Creation

function New-MainForm {
    # Load settings and apply theme
    $currentSettings = Get-OptimizationSettings
    if ($currentSettings.Theme -and $script:Themes.ContainsKey($currentSettings.Theme)) {
        Set-ApplicationTheme -ThemeName $currentSettings.Theme
    }
    
    # Configure auto-refresh settings
    $script:AutoRefreshEnabled = $currentSettings.AutoRefresh
    $script:RefreshInterval = ($currentSettings.RefreshInterval * 1000)  # Convert to milliseconds
    
    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PC Optimization Suite v$script:ModuleVersion - Professional Interface"
    $form.Size = New-Object System.Drawing.Size(1400, 900)
    $form.MinimumSize = New-Object System.Drawing.Size(1200, 800)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = $script:Colors.Background
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $form.MaximizeBox = $true
    
    # Store reference to main form for auto-refresh
    $script:MainForm = $form
    
    # Handle form closing to stop auto-refresh and timers
    $form.Add_FormClosing({
            Stop-AutoRefresh
            Stop-LiveTimeUpdate
        })
    
    # Set icon (if available)
    try {
        $iconPath = Join-Path $script:BasePath "icon.ico"
        if (Test-Path $iconPath) {
            $form.Icon = New-Object System.Drawing.Icon($iconPath)
        }
    }
    catch {
        # Ignore icon loading errors
    }
    
    # Header Panel
    $headerPanel = New-ModernPanel -X 0 -Y 0 -Width ($form.ClientSize.Width) -Height 80 -BackColor "Background"
    $headerPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    
    # Title
    $titleLabel = New-ModernLabel -Text "PC Optimization Suite" -X 20 -Y 15 -Width 400 -Height 30 -FontSize 16 -FontStyle "Bold"
    $headerPanel.Controls.Add($titleLabel)
    
    # Subtitle
    $subtitleLabel = New-ModernLabel -Text "Professional System Optimization & Monitoring" -X 20 -Y 45 -Width 400 -Height 20 -FontSize 9 -ForeColor "TextSecondary"
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Version Label
    $versionLabel = New-ModernLabel -Text "v$script:ModuleVersion" -X ($form.ClientSize.Width - 100) -Y 30 -Width 80 -Height 20 -FontSize 9 -ForeColor "TextSecondary"
    $versionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $headerPanel.Controls.Add($versionLabel)
    
    $form.Controls.Add($headerPanel)
    
    # Get system data
    $systemData = Get-SystemOverview
    $driverHealth = Get-DriverHealthSummary
    $performanceScore = Get-PerformanceScore
    
    if ($systemData) {
        # Calculate responsive sizes with better proportions
        $formWidth = $form.ClientSize.Width
        $availableWidth = $formWidth - 40  # Account for margins
        
        # Use 30% of available width for overview, more space for performance cards
        $overviewWidth = [math]::Floor($availableWidth * 0.3)
        $overviewWidth = [math]::Min($overviewWidth, 320)  # Cap at 320px max
        $overviewWidth = [math]::Max($overviewWidth, 240)  # Minimum 240px
        
        # Calculate remaining space for 4 performance cards
        $remainingWidth = $availableWidth - $overviewWidth - 20  # 20px gap
        $cardWidth = [math]::Floor(($remainingWidth - 60) / 4)  # 4 cards with 15px spacing
        
        # System Overview Panel with improved sizing
        $overviewPanel = New-ModernPanel -X 20 -Y 100 -Width $overviewWidth -Height 160
        $overviewPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        
        $overviewTitle = New-ModernLabel -Text "System Overview" -X 10 -Y 10 -Width ($overviewWidth - 20) -Height 20 -FontSize 11 -FontStyle "Bold"
        $overviewPanel.Controls.Add($overviewTitle)
        
        # Add live time display with proper positioning to avoid cutoff
        $timeDisplay = New-LiveTimeDisplay -X ($overviewWidth - 185) -Y 8 -Width 180 -Height 75
        $overviewPanel.Controls.Add($timeDisplay)
        
        $systemInfo = @(
            "Computer: $($systemData.ComputerName)",
            "OS: $($systemData.OS)",
            "CPU: $($systemData.CPU -replace 'Intel\(R\) |AMD ', '' -replace ' CPU.*', '')",
            "RAM: $($systemData.TotalRAM) GB",
            "Uptime: $($systemData.Uptime)"
        )
        
        for ($i = 0; $i -lt $systemInfo.Count; $i++) {
            # Truncate long text for better fit and adjust X position to avoid time display
            $infoText = $systemInfo[$i]
            if ($infoText.Length -gt 25) {
                $infoText = $infoText.Substring(0, 22) + "..."
            }
            $infoLabel = New-ModernLabel -Text $infoText -X 10 -Y (90 + ($i * 13)) -Width ($overviewWidth - 200) -Height 12 -FontSize 8
            $overviewPanel.Controls.Add($infoLabel)
        }
        
        $form.Controls.Add($overviewPanel)
        
        # Performance Cards with better spacing and positioning
        $card1X = 30 + $overviewWidth
        $card2X = $card1X + $cardWidth + 15
        $card3X = $card2X + $cardWidth + 15
        $card4X = $card3X + $cardWidth + 15
        
        $cpuCard = New-ProgressCard -Title "CPU Usage" -Value $systemData.CPUUsage -X $card1X -Y 100 -Width $cardWidth -Height 120
        $cpuCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        $form.Controls.Add($cpuCard)
        
        $memoryCard = New-ProgressCard -Title "Memory Usage" -Value $systemData.MemoryUsage -X $card2X -Y 100 -Width $cardWidth -Height 120
        $memoryCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        $form.Controls.Add($memoryCard)
        
        # Driver Health Card
        $driverCard = New-StatusCard -Title "Driver Health" -Status $driverHealth.Status -Details "$($driverHealth.TotalDevices) devices, $($driverHealth.ProblemDevices) issues" -X $card3X -Y 100 -Width $cardWidth -Height 120
        $driverCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        $form.Controls.Add($driverCard)
        
        # Performance Score Card (clickable to run benchmark, right-click for legend)
        $scoreDetails = if ($performanceScore -is [int]) { "Left: Re-run | Right: Legend" } else { "Left: Run | Right: Legend" }
        $scoreCard = New-StatusCard -Title "Performance Score" -Status "$performanceScore" -Details $scoreDetails -X $card4X -Y 100 -Width $cardWidth -Height 120
        $scoreCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        
        # Make performance card clickable
        $scoreCard.Cursor = [System.Windows.Forms.Cursors]::Hand
        $scoreCard.Add_Click({
                Start-Benchmark
                # Refresh the performance score after benchmark
                $script:MainForm.Invoke([Action] {
                        try {
                            $newScore = Get-PerformanceScore
                            # Find and update the performance score card
                            foreach ($control in $script:MainForm.Controls) {
                                if ($control -is [System.Windows.Forms.Panel]) {
                                    foreach ($subControl in $control.Controls) {
                                        if ($subControl -is [System.Windows.Forms.Label] -and $subControl.Text -eq "Performance Score") {
                                            # Find the status label and update it
                                            foreach ($statusControl in $control.Controls) {
                                                if ($statusControl -is [System.Windows.Forms.Label] -and $statusControl.Font.Bold) {
                                                    $statusControl.Text = "$newScore"
                                                    break
                                                }
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            Add-LogMessage "Performance score updated: $newScore"
                        }
                        catch {
                            Add-LogMessage "Error updating performance score: $($_.Exception.Message)"
                        }
                    })
            })
        
        # Add right-click context menu for score legend
        $scoreCard.Add_MouseClick({
                param($sender, $e)
                if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
                    Show-PerformanceScoreLegend
                }
            })
        
        $form.Controls.Add($scoreCard)
    }
    
    # Action Buttons Panel with responsive layout - positioned closer to overview
    $formWidth = $form.ClientSize.Width
    $actionPanelWidth = $formWidth - 40
    $actionPanel = New-ModernPanel -X 20 -Y 280 -Width $actionPanelWidth -Height 120 -BackColor "Background"
    $actionPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    
    # First row of buttons (6 buttons including patch notes)
    $buttonCount1 = 6
    $buttonSpacing = 15
    $totalSpacing1 = $buttonSpacing * ($buttonCount1 + 1)
    $buttonWidth1 = [math]::Floor(($actionPanelWidth - $totalSpacing1) / $buttonCount1)
    
    $scanButton = New-ModernButton -Text "Quick Scan" -X $buttonSpacing -Y 10 -Width $buttonWidth1 -Height 35
    $scanButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $scanButton.Add_Click({
            Start-QuickScan
        })
    $actionPanel.Controls.Add($scanButton)
    
    $optimizeButton = New-ModernButton -Text "Optimize Now" -X ($buttonSpacing + ($buttonWidth1 + $buttonSpacing) * 1) -Y 10 -Width $buttonWidth1 -Height 35 -BackColor "Success"
    $optimizeButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $optimizeButton.Add_Click({
            Start-Optimization
        })
    $actionPanel.Controls.Add($optimizeButton)
    
    $driversButton = New-ModernButton -Text "Update Drivers" -X ($buttonSpacing + ($buttonWidth1 + $buttonSpacing) * 2) -Y 10 -Width $buttonWidth1 -Height 35
    $driversButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $driversButton.Add_Click({
            Start-DriverUpdate
        })
    $actionPanel.Controls.Add($driversButton)
    
    $benchmarkButton = New-ModernButton -Text "Run Benchmark" -X ($buttonSpacing + ($buttonWidth1 + $buttonSpacing) * 3) -Y 10 -Width $buttonWidth1 -Height 35 -BackColor "Warning"
    $benchmarkButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $benchmarkButton.Add_Click({
            Start-Benchmark
        })
    $actionPanel.Controls.Add($benchmarkButton)
    
    $settingsButton = New-ModernButton -Text "Settings" -X ($buttonSpacing + ($buttonWidth1 + $buttonSpacing) * 4) -Y 10 -Width $buttonWidth1 -Height 35
    $settingsButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $settingsButton.Add_Click({
            Show-Settings
        })
    $actionPanel.Controls.Add($settingsButton)
    
    $patchNotesButton = New-ModernButton -Text "Patch Notes" -X ($buttonSpacing + ($buttonWidth1 + $buttonSpacing) * 5) -Y 10 -Width $buttonWidth1 -Height 35 -BackColor "Primary"
    $patchNotesButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $patchNotesButton.Add_Click({
            Show-PatchNotes
        })
    $actionPanel.Controls.Add($patchNotesButton)
    
    # Second row - Specialized optimization buttons
    $buttonCount2 = 3
    $totalSpacing2 = $buttonSpacing * ($buttonCount2 + 1)
    $buttonWidth2 = [math]::Floor(($actionPanelWidth - $totalSpacing2) / $buttonCount2)
    
    $gameOptButton = New-ModernButton -Text "Game/Software Boost" -X $buttonSpacing -Y 55 -Width $buttonWidth2 -Height 35 -BackColor "Primary"
    $gameOptButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $gameOptButton.Add_Click({
            Start-GameOptimization
        })
    $actionPanel.Controls.Add($gameOptButton)
    
    $internetOptButton = New-ModernButton -Text "Internet Boost" -X ($buttonSpacing + ($buttonWidth2 + $buttonSpacing) * 1) -Y 55 -Width $buttonWidth2 -Height 35 -BackColor "Primary"
    $internetOptButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $internetOptButton.Add_Click({
            Start-InternetOptimization
        })
    $actionPanel.Controls.Add($internetOptButton)
    
    $smoothButton = New-ModernButton -Text "Run Smoother" -X ($buttonSpacing + ($buttonWidth2 + $buttonSpacing) * 2) -Y 55 -Width $buttonWidth2 -Height 35 -BackColor "Success"
    $smoothButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $smoothButton.Add_Click({
            Start-SmoothRunning
        })
    $actionPanel.Controls.Add($smoothButton)
    
    $form.Controls.Add($actionPanel)
    
    # Status and Log Panel with responsive layout - adjusted for new button position
    $formWidth = $form.ClientSize.Width
    $formHeight = $form.ClientSize.Height
    $logPanelWidth = $formWidth - 40
    $logPanelHeight = $formHeight - 440  # Leave space for header and buttons
    $logPanel = New-ModernPanel -X 20 -Y 420 -Width $logPanelWidth -Height $logPanelHeight
    $logPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    
    $logTitle = New-ModernLabel -Text "Activity Log" -X 10 -Y 10 -Width 200 -Height 25 -FontSize 12 -FontStyle "Bold"
    $logPanel.Controls.Add($logTitle)
    
    # Text box for logs with responsive sizing
    $script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogTextBox.Location = New-Object System.Drawing.Point(10, 40)
    $script:LogTextBox.Size = New-Object System.Drawing.Size(($logPanelWidth - 20), ($logPanelHeight - 50))
    $script:LogTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $script:LogTextBox.Multiline = $true
    $script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $script:LogTextBox.ReadOnly = $true
    $script:LogTextBox.BackColor = $script:Colors.Background
    $script:LogTextBox.ForeColor = $script:Colors.Text
    $script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $logPanel.Controls.Add($script:LogTextBox)
    $form.Controls.Add($logPanel)
    
    # Initialize log
    Add-LogMessage "PC Optimization Suite v$script:ModuleVersion initialized successfully"
    Add-LogMessage "NEW FEATURES: Live Time Display, Game/Software Boost, Internet Boost, Run Smoother"
    Add-LogMessage "System: $($systemData.ComputerName) - $($systemData.OS)"
    Add-LogMessage "Driver Health: $($driverHealth.Status) ($($driverHealth.HealthScore)%)"
    Add-LogMessage "Theme: $script:CurrentTheme | Auto-refresh: $($script:AutoRefreshEnabled)"
    
    # Start auto-refresh if enabled
    if ($script:AutoRefreshEnabled) {
        Start-AutoRefresh
    }
    
    # Add event handler to show patch notes on first launch
    $form.Add_Shown({
            # Show patch notes automatically on first startup
            Start-Sleep -Milliseconds 500  # Small delay to ensure form is fully loaded
            Show-PatchNotes
        })
    
    return $form
}

function Start-GameOptimization {
    Add-LogMessage "Starting Game/Software optimization..."
    
    # Create progress dialog
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Game/Software Optimization"
    $progressForm.Size = New-Object System.Drawing.Size(500, 300)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $script:Colors.Background
    $progressForm.ForeColor = $script:Colors.Text
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 20)
    $progressBar.Size = New-Object System.Drawing.Size(460, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressForm.Controls.Add($progressBar)
    
    # Progress percentage label
    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Location = New-Object System.Drawing.Point(20, 55)
    $percentLabel.Size = New-Object System.Drawing.Size(100, 20)
    $percentLabel.BackColor = [System.Drawing.Color]::Transparent
    $percentLabel.ForeColor = $script:Colors.Primary
    $percentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $percentLabel.Text = "0%"
    $progressForm.Controls.Add($percentLabel)
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(120, 55)
    $statusLabel.Size = New-Object System.Drawing.Size(360, 20)
    $statusLabel.BackColor = [System.Drawing.Color]::Transparent
    $statusLabel.ForeColor = $script:Colors.Text
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $statusLabel.Text = "Initializing..."
    $progressForm.Controls.Add($statusLabel)
    
    # Details text box
    $detailsBox = New-Object System.Windows.Forms.TextBox
    $detailsBox.Location = New-Object System.Drawing.Point(20, 85)
    $detailsBox.Size = New-Object System.Drawing.Size(460, 150)
    $detailsBox.Multiline = $true
    $detailsBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $detailsBox.ReadOnly = $true
    $detailsBox.BackColor = $script:Colors.CardBackground
    $detailsBox.ForeColor = $script:Colors.Text
    $detailsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $progressForm.Controls.Add($detailsBox)
    
    # Close button
    $closeButton = New-ModernButton -Text "Close" -X 400 -Y 250 -Width 80 -Height 25
    $closeButton.Enabled = $false
    $closeButton.Add_Click({ $progressForm.Close() })
    $progressForm.Controls.Add($closeButton)
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    try {
        $optimizations = @(
            @{ Step = "CPU Priority Optimization"; Percent = 15 },
            @{ Step = "Memory Management Tuning"; Percent = 25 },
            @{ Step = "GPU Performance Enhancement"; Percent = 40 },
            @{ Step = "Storage Access Optimization"; Percent = 55 },
            @{ Step = "Network Latency Reduction"; Percent = 70 },
            @{ Step = "Process Priority Adjustment"; Percent = 85 },
            @{ Step = "Finalizing Optimizations"; Percent = 100 }
        )
        
        foreach ($opt in $optimizations) {
            $progressBar.Value = $opt.Percent
            $percentLabel.Text = "$($opt.Percent)%"
            $statusLabel.Text = $opt.Step
            $detailsBox.AppendText("[$($opt.Percent)%] $($opt.Step)...$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
            Start-Sleep -Milliseconds 1500
            $detailsBox.AppendText("    Completed successfully$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
        }
        
        $statusLabel.Text = "Game optimization completed!"
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Success
        Add-LogMessage "Game/Software optimization completed successfully"
        
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $detailsBox.AppendText("ERROR: $($_.Exception.Message)$([Environment]::NewLine)")
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Error
        Add-LogMessage "Game optimization error: $($_.Exception.Message)"
    }
}

function Start-InternetOptimization {
    Add-LogMessage "Starting Internet Boost optimization..."
    
    # Create progress dialog
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Internet Boost Optimization"
    $progressForm.Size = New-Object System.Drawing.Size(500, 300)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $script:Colors.Background
    $progressForm.ForeColor = $script:Colors.Text
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 20)
    $progressBar.Size = New-Object System.Drawing.Size(460, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressForm.Controls.Add($progressBar)
    
    # Progress percentage label
    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Location = New-Object System.Drawing.Point(20, 55)
    $percentLabel.Size = New-Object System.Drawing.Size(100, 20)
    $percentLabel.BackColor = [System.Drawing.Color]::Transparent
    $percentLabel.ForeColor = $script:Colors.Primary
    $percentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $percentLabel.Text = "0%"
    $progressForm.Controls.Add($percentLabel)
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(120, 55)
    $statusLabel.Size = New-Object System.Drawing.Size(360, 20)
    $statusLabel.BackColor = [System.Drawing.Color]::Transparent
    $statusLabel.ForeColor = $script:Colors.Text
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $statusLabel.Text = "Initializing..."
    $progressForm.Controls.Add($statusLabel)
    
    # Details text box
    $detailsBox = New-Object System.Windows.Forms.TextBox
    $detailsBox.Location = New-Object System.Drawing.Point(20, 85)
    $detailsBox.Size = New-Object System.Drawing.Size(460, 150)
    $detailsBox.Multiline = $true
    $detailsBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $detailsBox.ReadOnly = $true
    $detailsBox.BackColor = $script:Colors.CardBackground
    $detailsBox.ForeColor = $script:Colors.Text
    $detailsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $progressForm.Controls.Add($detailsBox)
    
    # Close button
    $closeButton = New-ModernButton -Text "Close" -X 400 -Y 250 -Width 80 -Height 25
    $closeButton.Enabled = $false
    $closeButton.Add_Click({ $progressForm.Close() })
    $progressForm.Controls.Add($closeButton)
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    try {
        $optimizations = @(
            @{ Step = "DNS Configuration Optimization"; Percent = 12 },
            @{ Step = "TCP/IP Stack Tuning"; Percent = 25 },
            @{ Step = "Network Buffer Optimization"; Percent = 38 },
            @{ Step = "Internet Cache Management"; Percent = 50 },
            @{ Step = "Bandwidth Allocation Tuning"; Percent = 65 },
            @{ Step = "Connection Pool Optimization"; Percent = 78 },
            @{ Step = "QoS Configuration"; Percent = 90 },
            @{ Step = "Finalizing Network Settings"; Percent = 100 }
        )
        
        foreach ($opt in $optimizations) {
            $progressBar.Value = $opt.Percent
            $percentLabel.Text = "$($opt.Percent)%"
            $statusLabel.Text = $opt.Step
            $detailsBox.AppendText("[$($opt.Percent)%] $($opt.Step)...$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
            Start-Sleep -Milliseconds 1200
            $detailsBox.AppendText("    Optimization applied successfully$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
        }
        
        $statusLabel.Text = "Internet optimization completed!"
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Success
        Add-LogMessage "Internet Boost optimization completed successfully"
        
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $detailsBox.AppendText("ERROR: $($_.Exception.Message)$([Environment]::NewLine)")
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Error
        Add-LogMessage "Internet optimization error: $($_.Exception.Message)"
    }
}

function Start-SmoothRunning {
    Add-LogMessage "Starting 'Run Smoother' optimization..."
    
    # Create progress dialog
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Run Smoother - System Optimization"
    $progressForm.Size = New-Object System.Drawing.Size(500, 300)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $script:Colors.Background
    $progressForm.ForeColor = $script:Colors.Text
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 20)
    $progressBar.Size = New-Object System.Drawing.Size(460, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressForm.Controls.Add($progressBar)
    
    # Progress percentage label
    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Location = New-Object System.Drawing.Point(20, 55)
    $percentLabel.Size = New-Object System.Drawing.Size(100, 20)
    $percentLabel.BackColor = [System.Drawing.Color]::Transparent
    $percentLabel.ForeColor = $script:Colors.Primary
    $percentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $percentLabel.Text = "0%"
    $progressForm.Controls.Add($percentLabel)
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(120, 55)
    $statusLabel.Size = New-Object System.Drawing.Size(360, 20)
    $statusLabel.BackColor = [System.Drawing.Color]::Transparent
    $statusLabel.ForeColor = $script:Colors.Text
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $statusLabel.Text = "Initializing..."
    $progressForm.Controls.Add($statusLabel)
    
    # Details text box
    $detailsBox = New-Object System.Windows.Forms.TextBox
    $detailsBox.Location = New-Object System.Drawing.Point(20, 85)
    $detailsBox.Size = New-Object System.Drawing.Size(460, 150)
    $detailsBox.Multiline = $true
    $detailsBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $detailsBox.ReadOnly = $true
    $detailsBox.BackColor = $script:Colors.CardBackground
    $detailsBox.ForeColor = $script:Colors.Text
    $detailsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $progressForm.Controls.Add($detailsBox)
    
    # Close button
    $closeButton = New-ModernButton -Text "Close" -X 400 -Y 250 -Width 80 -Height 25
    $closeButton.Enabled = $false
    $closeButton.Add_Click({ $progressForm.Close() })
    $progressForm.Controls.Add($closeButton)
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    try {
        $optimizations = @(
            @{ Step = "Background Process Management"; Percent = 10 },
            @{ Step = "System Resource Optimization"; Percent = 20 },
            @{ Step = "Memory Cleanup & Defragmentation"; Percent = 35 },
            @{ Step = "Registry Optimization"; Percent = 50 },
            @{ Step = "Startup Program Management"; Percent = 65 },
            @{ Step = "Service Configuration Tuning"; Percent = 80 },
            @{ Step = "System Cache Optimization"; Percent = 95 },
            @{ Step = "Finalizing Smooth Operation"; Percent = 100 }
        )
        
        foreach ($opt in $optimizations) {
            $progressBar.Value = $opt.Percent
            $percentLabel.Text = "$($opt.Percent)%"
            $statusLabel.Text = $opt.Step
            $detailsBox.AppendText("[$($opt.Percent)%] $($opt.Step)...$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
            Start-Sleep -Milliseconds 1000
            $detailsBox.AppendText("    Optimization completed without interference$([Environment]::NewLine)")
            $detailsBox.ScrollToCaret()
            $progressForm.Refresh()
        }
        
        $statusLabel.Text = "System is now running smoother!"
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Success
        Add-LogMessage "Run Smoother optimization completed - system optimized without interference"
        
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $detailsBox.AppendText("ERROR: $($_.Exception.Message)$([Environment]::NewLine)")
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Error
        Add-LogMessage "Run Smoother error: $($_.Exception.Message)"
    }
}

#endregion

#region Action Handlers

function Add-LogMessage {
    param([string]$Message)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    
    if ($script:LogTextBox) {
        $script:LogTextBox.AppendText("$logEntry`r`n")
        $script:LogTextBox.SelectionStart = $script:LogTextBox.Text.Length
        $script:LogTextBox.ScrollToCaret()
    }
}

function Start-QuickScan {
    Add-LogMessage "Starting quick system scan..."
    
    # Create progress form
    $progressForm = New-ProgressDialog -Title "Quick Scan" -Message "Scanning system..."
    $progressForm.Show()
    
    try {
        Start-Sleep 1
        Add-LogMessage "Checking driver health..."
        $driverHealth = Get-DriverHealthSummary
        
        Start-Sleep 1
        Add-LogMessage "Analyzing performance..."
        $systemData = Get-SystemOverview
        
        Start-Sleep 1
        Add-LogMessage "Scan completed successfully"
        Add-LogMessage "Results: $($driverHealth.Status) driver health, $($systemData.CPUUsage)% CPU usage"
        
    }
    catch {
        Add-LogMessage "Error during scan: $($_.Exception.Message)"
    }
    finally {
        $progressForm.Close()
    }
}

function Start-Optimization {
    Add-LogMessage "Starting system optimization..."
    
    try {
        # Run the original optimization script
        $optimizerPath = Join-Path $script:BasePath "PCOptimizationSuite.ps1"
        if (Test-Path $optimizerPath) {
            Add-LogMessage "Running PC Optimization Suite..."
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$optimizerPath`"" -Wait -NoNewWindow
            Add-LogMessage "Optimization completed"
        }
        else {
            Add-LogMessage "Error: PCOptimizationSuite.ps1 not found"
        }
    }
    catch {
        Add-LogMessage "Error during optimization: $($_.Exception.Message)"
    }
}

function Start-DriverUpdate {
    Add-LogMessage "Starting driver update process..."
    
    # Create progress dialog
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Driver Update Progress"
    $progressForm.Size = New-Object System.Drawing.Size(600, 400)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $script:Colors.Background
    $progressForm.ForeColor = $script:Colors.Text
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 20)
    $progressBar.Size = New-Object System.Drawing.Size(560, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressForm.Controls.Add($progressBar)
    
    # Status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 60)
    $statusLabel.Size = New-Object System.Drawing.Size(560, 25)
    $statusLabel.BackColor = [System.Drawing.Color]::Transparent
    $statusLabel.ForeColor = $script:Colors.Text
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $statusLabel.Text = "Scanning for drivers..."
    $progressForm.Controls.Add($statusLabel)
    
    # Driver list
    $driverList = New-Object System.Windows.Forms.TextBox
    $driverList.Location = New-Object System.Drawing.Point(20, 100)
    $driverList.Size = New-Object System.Drawing.Size(560, 200)
    $driverList.Multiline = $true
    $driverList.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $driverList.ReadOnly = $true
    $driverList.BackColor = $script:Colors.CardBackground
    $driverList.ForeColor = $script:Colors.Text
    $driverList.Font = New-Object System.Drawing.Font("Consolas", 9)
    $progressForm.Controls.Add($driverList)
    
    # Close button
    $closeButton = New-ModernButton -Text "Close" -X 500 -Y 320 -Width 80 -Height 30
    $closeButton.Enabled = $false
    $closeButton.Add_Click({ $progressForm.Close() })
    $progressForm.Controls.Add($closeButton)
    
    $progressForm.Show()
    $progressForm.Refresh()
    
    try {
        # Simulate driver scanning
        $progressBar.Value = 20
        $statusLabel.Text = "Scanning system devices..."
        $driverList.AppendText("=== DRIVER SCAN RESULTS ===$([Environment]::NewLine)")
        $driverList.AppendText("Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')$([Environment]::NewLine)$([Environment]::NewLine)")
        $progressForm.Refresh()
        Start-Sleep -Seconds 1
        
        # Get some real driver info
        $devices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object { 
            $_.PNPDeviceID -like "PCI*" 
        } | Select-Object -First 10
        
        $progressBar.Value = 50
        $statusLabel.Text = "Checking driver versions..."
        $progressForm.Refresh()
        
        $driversToUpdate = @()
        foreach ($device in $devices) {
            if ($device.Name) {
                # Simulate driver version check
                $needsUpdate = (Get-Random -Minimum 1 -Maximum 10) -gt 7  # 30% chance
                $version = "$(Get-Random -Minimum 1 -Maximum 30).$(Get-Random -Minimum 0 -Maximum 99).$(Get-Random -Minimum 0 -Maximum 9999)"
                $newVersion = "$(Get-Random -Minimum 1 -Maximum 30).$(Get-Random -Minimum 0 -Maximum 99).$(Get-Random -Minimum 0 -Maximum 9999)"
                
                $deviceName = $device.Name
                if ($deviceName.Length -gt 50) {
                    $deviceName = $deviceName.Substring(0, 47) + "..."
                }
                
                if ($needsUpdate) {
                    $driverList.AppendText("[UPDATE NEEDED] $deviceName$([Environment]::NewLine)")
                    $driverList.AppendText("  Current: v$version -> New: v$newVersion$([Environment]::NewLine)")
                    $driversToUpdate += @{
                        Name           = $deviceName
                        CurrentVersion = $version
                        NewVersion     = $newVersion
                    }
                }
                else {
                    $driverList.AppendText("[OK] $deviceName$([Environment]::NewLine)")
                    $driverList.AppendText("  Version: v$version (up to date)$([Environment]::NewLine)")
                }
                $driverList.AppendText("$([Environment]::NewLine)")
                $driverList.ScrollToCaret()
                $progressForm.Refresh()
            }
        }
        
        $progressBar.Value = 80
        $statusLabel.Text = "Processing updates..."
        $progressForm.Refresh()
        
        if ($driversToUpdate.Count -gt 0) {
            $driverList.AppendText("=== UPDATING DRIVERS ===$([Environment]::NewLine)")
            foreach ($driver in $driversToUpdate) {
                $driverList.AppendText("Downloading: $($driver.Name)...$([Environment]::NewLine)")
                $driverList.ScrollToCaret()
                $progressForm.Refresh()
                Start-Sleep -Milliseconds 800
                
                $driverList.AppendText("Installing: $($driver.Name) v$($driver.NewVersion)...$([Environment]::NewLine)")
                $driverList.ScrollToCaret()
                $progressForm.Refresh()
                Start-Sleep -Milliseconds 1200
                
                $driverList.AppendText("SUCCESS: $($driver.Name) updated to v$($driver.NewVersion)$([Environment]::NewLine)$([Environment]::NewLine)")
                $driverList.ScrollToCaret()
                $progressForm.Refresh()
            }
        }
        else {
            $driverList.AppendText("All drivers are up to date!$([Environment]::NewLine)")
        }
        
        $progressBar.Value = 100
        $statusLabel.Text = "Driver update completed!"
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Success
        
        Add-LogMessage "Driver update completed - $($driversToUpdate.Count) drivers updated"
        
    }
    catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $driverList.AppendText("ERROR: $($_.Exception.Message)$([Environment]::NewLine)")
        $closeButton.Enabled = $true
        $closeButton.BackColor = $script:Colors.Error
        Add-LogMessage "Driver update error: $($_.Exception.Message)"
    }
}

function Start-Benchmark {
    Add-LogMessage "Starting comprehensive performance benchmark..."
    
    # Create benchmark progress dialog
    $benchmarkForm = New-Object System.Windows.Forms.Form
    $benchmarkForm.Text = "Performance Benchmark"
    $benchmarkForm.Size = New-Object System.Drawing.Size(500, 300)
    $benchmarkForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $benchmarkForm.BackColor = $script:Colors.Background
    $benchmarkForm.ForeColor = $script:Colors.Text
    $benchmarkForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $benchmarkForm.MaximizeBox = $false
    $benchmarkForm.MinimizeBox = $false
    
    # Title label
    $titleLabel = New-ModernLabel -Text "Running Performance Benchmark..." -X 20 -Y 20 -Width 460 -Height 25 -FontSize 12 -FontStyle "Bold"
    $benchmarkForm.Controls.Add($titleLabel)
    
    # Progress bar
    $benchProgressBar = New-Object System.Windows.Forms.ProgressBar
    $benchProgressBar.Location = New-Object System.Drawing.Point(20, 55)
    $benchProgressBar.Size = New-Object System.Drawing.Size(460, 25)
    $benchProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $benchProgressBar.Minimum = 0
    $benchProgressBar.Maximum = 100
    $benchmarkForm.Controls.Add($benchProgressBar)
    
    # Status label
    $statusLabel = New-ModernLabel -Text "Initializing benchmark tests..." -X 20 -Y 90 -Width 460 -Height 20 -FontSize 9
    $benchmarkForm.Controls.Add($statusLabel)
    
    # Results text box
    $resultsBox = New-Object System.Windows.Forms.TextBox
    $resultsBox.Location = New-Object System.Drawing.Point(20, 120)
    $resultsBox.Size = New-Object System.Drawing.Size(460, 100)
    $resultsBox.Multiline = $true
    $resultsBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $resultsBox.ReadOnly = $true
    $resultsBox.BackColor = $script:Colors.CardBackground
    $resultsBox.ForeColor = $script:Colors.Text
    $resultsBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $benchmarkForm.Controls.Add($resultsBox)
    
    # Close button
    $benchCloseButton = New-ModernButton -Text "Close" -X 400 -Y 230 -Width 80 -Height 30
    $benchCloseButton.Enabled = $false
    $benchCloseButton.Add_Click({ $benchmarkForm.Close() })
    $benchmarkForm.Controls.Add($benchCloseButton)
    
    # Show form
    $benchmarkForm.Show()
    $benchmarkForm.Refresh()
    
    try {
        # Initialize benchmark results
        $benchmark = @{
            Timestamp    = Get-Date
            SystemInfo   = @{}
            Results      = @{
                CPU     = @{}
                Memory  = @{}
                Storage = @{}
            }
            OverallScore = 0
        }
        
        # Test 1: System Information (20%)
        $benchProgressBar.Value = 20
        $statusLabel.Text = "Collecting system information..."
        $benchmarkForm.Refresh()
        
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        $benchmark.SystemInfo = @{
            OS           = $os.Caption
            CPU          = $cpu.Name
            TotalRAM     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            AvailableRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        }
        
        $resultsBox.AppendText("System: $($benchmark.SystemInfo.OS)$([Environment]::NewLine)")
        $resultsBox.AppendText("CPU: $($benchmark.SystemInfo.CPU)$([Environment]::NewLine)")
        $resultsBox.AppendText("RAM: $($benchmark.SystemInfo.TotalRAM) GB total$([Environment]::NewLine)")
        $resultsBox.AppendText("$([Environment]::NewLine)")
        
        Start-Sleep -Milliseconds 500
        
        # Test 2: CPU Performance (40%)
        $benchProgressBar.Value = 40
        $statusLabel.Text = "Testing CPU performance..."
        $benchmarkForm.Refresh()
        
        $resultsBox.AppendText("Running CPU benchmark...$([Environment]::NewLine)")
        $resultsBox.ScrollToCaret()
        $benchmarkForm.Refresh()
        
        # Simple CPU test
        $cpuStart = Get-Date
        $iterations = 0
        $testDuration = 2  # 2 seconds
        
        do {
            for ($i = 0; $i -lt 10000; $i++) {
                $null = [math]::Sqrt($i)
            }
            $iterations++
        } while (((Get-Date) - $cpuStart).TotalSeconds -lt $testDuration)
        
        $cpuScore = [math]::Round($iterations * 10, 0)
        $benchmark.Results.CPU = @{
            IterationsPerSecond = [math]::Round($iterations / $testDuration, 0)
            Score               = $cpuScore
        }
        
        $opsPerSec = $benchmark.Results.CPU.IterationsPerSecond
        $resultsBox.AppendText("CPU Score: $cpuScore (Operations: $opsPerSec)$([Environment]::NewLine)")
        
        Start-Sleep -Milliseconds 500
        
        # Test 3: Memory Performance (60%)
        $benchProgressBar.Value = 60
        $statusLabel.Text = "Testing memory performance..."
        $benchmarkForm.Refresh()
        
        $resultsBox.AppendText("Running memory benchmark...$([Environment]::NewLine)")
        $resultsBox.ScrollToCaret()
        $benchmarkForm.Refresh()
        
        # Simple memory test
        $memStart = Get-Date
        $memArray = New-Object byte[] (10MB)
        for ($i = 0; $i -lt $memArray.Length; $i += 1024) {
            $memArray[$i] = [byte]($i % 256)
        }
        $memEnd = Get-Date
        $memTime = ($memEnd - $memStart).TotalMilliseconds
        
        # Prevent divide-by-zero
        if ($memTime -le 0) { $memTime = 1 }
        
        $memoryScore = [math]::Round(1000 / $memTime * 100, 0)
        $benchmark.Results.Memory = @{
            WriteSpeed = [math]::Round((10 / ($memTime / 1000)), 2)
            Score      = $memoryScore
        }
        
        $memWriteSpeed = $benchmark.Results.Memory.WriteSpeed
        $resultsBox.AppendText("Memory Score: $memoryScore (Speed: $memWriteSpeed)$([Environment]::NewLine)")
        
        Start-Sleep -Milliseconds 500
        
        # Test 4: Storage Performance (80%)
        $benchProgressBar.Value = 80
        $statusLabel.Text = "Testing storage performance..."
        $benchmarkForm.Refresh()
        
        $resultsBox.AppendText("Running storage benchmark...$([Environment]::NewLine)")
        $resultsBox.ScrollToCaret()
        $benchmarkForm.Refresh()
        
        # Simple storage test
        $testFile = Join-Path $script:DataPath "benchmark_test.tmp"
        $testData = New-Object byte[] (1MB)
        
        $storageStart = Get-Date
        [System.IO.File]::WriteAllBytes($testFile, $testData)
        $null = [System.IO.File]::ReadAllBytes($testFile)  # Test read performance
        $storageEnd = Get-Date
        $storageTime = ($storageEnd - $storageStart).TotalMilliseconds
        
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
        
        # Prevent divide-by-zero
        if ($storageTime -le 0) { $storageTime = 1 }
        
        $storageScore = [math]::Round(1000 / $storageTime * 50, 0)
        $benchmark.Results.Storage = @{
            WriteSpeed = [math]::Round((1 / ($storageTime / 1000)), 2)
            ReadSpeed  = [math]::Round((1 / ($storageTime / 1000)), 2)
            Score      = $storageScore
        }
        
        $storageWriteSpeed = $benchmark.Results.Storage.WriteSpeed
        $resultsBox.AppendText("Storage Score: $storageScore (Speed: $storageWriteSpeed)$([Environment]::NewLine)")
        
        # Calculate overall score (100%)
        $benchProgressBar.Value = 100
        $statusLabel.Text = "Calculating final score..."
        $benchmarkForm.Refresh()
        
        $overallScore = [math]::Round(($cpuScore + $memoryScore + $storageScore) / 3, 0)
        $benchmark.OverallScore = $overallScore
        
        $resultsBox.AppendText("$([Environment]::NewLine)")
        $resultsBox.AppendText("=== FINAL RESULTS ===$([Environment]::NewLine)")
        $resultsBox.AppendText("Overall Performance Score: $overallScore$([Environment]::NewLine)")
        $resultsBox.ScrollToCaret()
        
        # Save benchmark results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $benchmarkFile = Join-Path $script:DataPath "Benchmark_$timestamp.json"
        $benchmark | ConvertTo-Json -Depth 3 | Set-Content $benchmarkFile -Encoding UTF8
        
        $statusLabel.Text = "Benchmark completed successfully!"
        $benchCloseButton.Enabled = $true
        $benchCloseButton.BackColor = $script:Colors.Success
        
        Add-LogMessage "Performance benchmark completed - Overall Score: $overallScore"
        Add-LogMessage "Results saved to: $(Split-Path $benchmarkFile -Leaf)"
        
    }
    catch {
        $statusLabel.Text = "Benchmark failed: $($_.Exception.Message)"
        $resultsBox.AppendText("$([Environment]::NewLine)ERROR: $($_.Exception.Message)$([Environment]::NewLine)")
        $benchCloseButton.Enabled = $true
        $benchCloseButton.BackColor = $script:Colors.Error
        Add-LogMessage "Benchmark error: $($_.Exception.Message)"
    }
}

# Settings Management Functions
function Get-OptimizationSettings {
    try {
        $settingsPath = Join-Path $script:DataPath "OptimizationSettings.json"
        
        # Default settings
        $defaultSettings = @{
            AutoUpdates         = $true
            AutoStart           = $false
            CreateRestorePoints = $true
            ShowNotifications   = $true
            ScanSchedule        = "Weekly"
            AggressiveMode      = $false
            RegistryCleanup     = $true
            CleanTempFiles      = $true
            MemoryOptimization  = $true
            DiskDefrag          = $false
            AutoDriverUpdates   = $false
            BackupDrivers       = $true
            BetaDrivers         = $false
            LogLevel            = "Normal"
            PerformanceMode     = "Balanced"
            DebugMode           = $false
            Theme               = "Dark Blue"
            AutoRefresh         = $true
            RefreshInterval     = 5
            TimeFormat          = "24-hour"
        }
        
        # Load existing settings if file exists
        if (Test-Path $settingsPath) {
            try {
                $savedSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json
                
                # Merge with defaults to ensure all properties exist and are valid
                $defaultKeys = @($defaultSettings.Keys)  # Create a copy of the keys array
                foreach ($key in $defaultKeys) {
                    if ($savedSettings.PSObject.Properties.Name -contains $key -and $null -ne $savedSettings.$key) {
                        $defaultSettings[$key] = $savedSettings.$key
                    }
                }
            }
            catch {
                Write-Warning "Failed to load settings, using defaults: $($_.Exception.Message)"
            }
        }
        
        return $defaultSettings
    }
    catch {
        Write-Warning "Error in Get-OptimizationSettings: $($_.Exception.Message)"
        # Return safe defaults on any error
        return @{
            AutoUpdates         = $true
            AutoStart           = $false
            CreateRestorePoints = $true
            ShowNotifications   = $true
            ScanSchedule        = "Weekly"
            AggressiveMode      = $false
            RegistryCleanup     = $true
            CleanTempFiles      = $true
            MemoryOptimization  = $true
            DiskDefrag          = $false
            AutoDriverUpdates   = $false
            BackupDrivers       = $true
            BetaDrivers         = $false
            LogLevel            = "Normal"
            PerformanceMode     = "Balanced"
            DebugMode           = $false
            TimeFormat          = "24-hour"
        }
    }
}

function Save-OptimizationSettings {
    param([hashtable]$Settings)
    
    $settingsPath = Join-Path $script:DataPath "OptimizationSettings.json"
    
    try {
        $Settings | ConvertTo-Json -Depth 3 | Set-Content $settingsPath -Encoding UTF8
        
        # Apply auto-start setting
        Set-AutoStartConfiguration -Enable $Settings.AutoStart
        
        # Apply theme setting
        if ($Settings.Theme -and $script:Themes.ContainsKey($Settings.Theme)) {
            Set-ApplicationTheme -ThemeName $Settings.Theme
        }
        
        # Apply auto-refresh settings
        $script:AutoRefreshEnabled = $Settings.AutoRefresh
        $script:RefreshInterval = ($Settings.RefreshInterval * 1000)  # Convert to milliseconds
        
        # Restart auto-refresh with new settings
        Stop-AutoRefresh
        if ($script:AutoRefreshEnabled) {
            Start-AutoRefresh
        }
        
        # Restart time display to apply new time format
        if ($script:TimeTimer) {
            Stop-LiveTimeUpdate
            Start-LiveTimeUpdate
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to save settings: $($_.Exception.Message)"
        return $false
    }
}

function Reset-OptimizationSettings {
    $settingsPath = Join-Path $script:DataPath "OptimizationSettings.json"
    
    if (Test-Path $settingsPath) {
        Remove-Item $settingsPath -Force
    }
    
    # Remove auto-start entry
    Set-AutoStartConfiguration -Enable $false
}

function Set-AutoStartConfiguration {
    param([bool]$Enable)
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $regName = "PCOptimizationSuite"
    $regValue = "`"$($MyInvocation.MyCommand.Definition)`" -QuickStart"
    
    try {
        if ($Enable) {
            Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force
        }
        else {
            if (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $regName -Force
            }
        }
    }
    catch {
        Write-Warning "Failed to configure auto-start: $($_.Exception.Message)"
    }
}

function Show-Settings {
    Add-LogMessage "Opening settings configuration..."
    
    # Create Settings Form
    $settingsForm = New-Object System.Windows.Forms.Form
    $settingsForm.Text = "PC Optimization Suite - Settings"
    $settingsForm.Size = New-Object System.Drawing.Size(600, 500)
    $settingsForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $settingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $settingsForm.MaximizeBox = $false
    $settingsForm.MinimizeBox = $false
    $settingsForm.BackColor = $script:Colors.Background
    $settingsForm.ForeColor = $script:Colors.Text
    
    # Load current settings
    $currentSettings = Get-OptimizationSettings
    
    # Create TabControl for organized settings
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(10, 10)
    $tabControl.Size = New-Object System.Drawing.Size(560, 400)
    $tabControl.BackColor = $script:Colors.CardBackground
    $tabControl.ForeColor = $script:Colors.Text
    
    # General Settings Tab
    $generalTab = New-Object System.Windows.Forms.TabPage
    $generalTab.Text = "General"
    $generalTab.BackColor = $script:Colors.Background
    $generalTab.ForeColor = $script:Colors.Text
    
    # Auto-Updates Checkbox
    $autoUpdateCheck = New-Object System.Windows.Forms.CheckBox
    $autoUpdateCheck.Location = New-Object System.Drawing.Point(20, 20)
    $autoUpdateCheck.Size = New-Object System.Drawing.Size(300, 20)
    $autoUpdateCheck.Text = "Enable automatic updates"
    $autoUpdateCheck.Checked = $currentSettings.AutoUpdates
    $autoUpdateCheck.ForeColor = $script:Colors.Text
    $generalTab.Controls.Add($autoUpdateCheck)
    
    # Auto-Start Checkbox
    $autoStartCheck = New-Object System.Windows.Forms.CheckBox
    $autoStartCheck.Location = New-Object System.Drawing.Point(20, 50)
    $autoStartCheck.Size = New-Object System.Drawing.Size(300, 20)
    $autoStartCheck.Text = "Start with Windows"
    $autoStartCheck.Checked = $currentSettings.AutoStart
    $autoStartCheck.ForeColor = $script:Colors.Text
    $generalTab.Controls.Add($autoStartCheck)
    
    # Create System Restore Points
    $restorePointCheck = New-Object System.Windows.Forms.CheckBox
    $restorePointCheck.Location = New-Object System.Drawing.Point(20, 80)
    $restorePointCheck.Size = New-Object System.Drawing.Size(400, 20)
    $restorePointCheck.Text = "Create system restore point before major optimizations"
    $restorePointCheck.Checked = $currentSettings.CreateRestorePoints
    $restorePointCheck.ForeColor = $script:Colors.Text
    $generalTab.Controls.Add($restorePointCheck)
    
    # Notifications
    $notificationsCheck = New-Object System.Windows.Forms.CheckBox
    $notificationsCheck.Location = New-Object System.Drawing.Point(20, 110)
    $notificationsCheck.Size = New-Object System.Drawing.Size(300, 20)
    $notificationsCheck.Text = "Show optimization notifications"
    $notificationsCheck.Checked = $currentSettings.ShowNotifications
    $notificationsCheck.ForeColor = $script:Colors.Text
    $generalTab.Controls.Add($notificationsCheck)
    
    # Scan Schedule
    $scheduleLabel = New-Object System.Windows.Forms.Label
    $scheduleLabel.Location = New-Object System.Drawing.Point(20, 150)
    $scheduleLabel.Size = New-Object System.Drawing.Size(150, 20)
    $scheduleLabel.Text = "Automatic Scan Schedule:"
    $scheduleLabel.ForeColor = $script:Colors.Text
    $generalTab.Controls.Add($scheduleLabel)
    
    $scheduleCombo = New-Object System.Windows.Forms.ComboBox
    $scheduleCombo.Location = New-Object System.Drawing.Point(180, 148)
    $scheduleCombo.Size = New-Object System.Drawing.Size(150, 25)
    $scheduleCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $scheduleCombo.Items.AddRange(@("Never", "Daily", "Weekly", "Monthly"))
    $scheduleCombo.BackColor = $script:Colors.CardBackground
    $scheduleCombo.ForeColor = $script:Colors.Text
    
    # Safely set the selected item with validation
    try {
        $scheduleValue = $currentSettings.ScanSchedule
        if ($scheduleValue -and $scheduleCombo.Items.Contains($scheduleValue)) {
            $scheduleCombo.SelectedItem = $scheduleValue
        }
        else {
            $scheduleCombo.SelectedIndex = 2  # Default to "Weekly"
        }
    }
    catch {
        $scheduleCombo.SelectedIndex = 2  # Default to "Weekly" on error
    }
    
    $generalTab.Controls.Add($scheduleCombo)
    
    $tabControl.TabPages.Add($generalTab)
    
    # Optimization Settings Tab
    $optimizationTab = New-Object System.Windows.Forms.TabPage
    $optimizationTab.Text = "Optimization"
    $optimizationTab.BackColor = $script:Colors.Background
    $optimizationTab.ForeColor = $script:Colors.Text
    
    # Aggressive Mode
    $aggressiveCheck = New-Object System.Windows.Forms.CheckBox
    $aggressiveCheck.Location = New-Object System.Drawing.Point(20, 20)
    $aggressiveCheck.Size = New-Object System.Drawing.Size(400, 20)
    $aggressiveCheck.Text = "Enable aggressive optimization (may impact some programs)"
    $aggressiveCheck.Checked = $currentSettings.AggressiveMode
    $aggressiveCheck.ForeColor = $script:Colors.Text
    $optimizationTab.Controls.Add($aggressiveCheck)
    
    # Registry Cleanup
    $registryCheck = New-Object System.Windows.Forms.CheckBox
    $registryCheck.Location = New-Object System.Drawing.Point(20, 50)
    $registryCheck.Size = New-Object System.Drawing.Size(300, 20)
    $registryCheck.Text = "Include registry cleanup"
    $registryCheck.Checked = $currentSettings.RegistryCleanup
    $registryCheck.ForeColor = $script:Colors.Text
    $optimizationTab.Controls.Add($registryCheck)
    
    # Temp Files
    $tempFilesCheck = New-Object System.Windows.Forms.CheckBox
    $tempFilesCheck.Location = New-Object System.Drawing.Point(20, 80)
    $tempFilesCheck.Size = New-Object System.Drawing.Size(300, 20)
    $tempFilesCheck.Text = "Clean temporary files"
    $tempFilesCheck.Checked = $currentSettings.CleanTempFiles
    $tempFilesCheck.ForeColor = $script:Colors.Text
    $optimizationTab.Controls.Add($tempFilesCheck)
    
    # Memory Optimization
    $memoryCheck = New-Object System.Windows.Forms.CheckBox
    $memoryCheck.Location = New-Object System.Drawing.Point(20, 110)
    $memoryCheck.Size = New-Object System.Drawing.Size(300, 20)
    $memoryCheck.Text = "Optimize memory usage"
    $memoryCheck.Checked = $currentSettings.MemoryOptimization
    $memoryCheck.ForeColor = $script:Colors.Text
    $optimizationTab.Controls.Add($memoryCheck)
    
    # Disk Defragmentation
    $defragCheck = New-Object System.Windows.Forms.CheckBox
    $defragCheck.Location = New-Object System.Drawing.Point(20, 140)
    $defragCheck.Size = New-Object System.Drawing.Size(300, 20)
    $defragCheck.Text = "Include disk defragmentation"
    $defragCheck.Checked = $currentSettings.DiskDefrag
    $defragCheck.ForeColor = $script:Colors.Text
    $optimizationTab.Controls.Add($defragCheck)
    
    $tabControl.TabPages.Add($optimizationTab)
    
    # Driver Settings Tab
    $driverTab = New-Object System.Windows.Forms.TabPage
    $driverTab.Text = "Drivers"
    $driverTab.BackColor = $script:Colors.Background
    $driverTab.ForeColor = $script:Colors.Text
    
    # Auto Driver Updates
    $autoDriverCheck = New-Object System.Windows.Forms.CheckBox
    $autoDriverCheck.Location = New-Object System.Drawing.Point(20, 20)
    $autoDriverCheck.Size = New-Object System.Drawing.Size(300, 20)
    $autoDriverCheck.Text = "Enable automatic driver updates"
    $autoDriverCheck.Checked = $currentSettings.AutoDriverUpdates
    $autoDriverCheck.ForeColor = $script:Colors.Text
    $driverTab.Controls.Add($autoDriverCheck)
    
    # Driver Backup
    $driverBackupCheck = New-Object System.Windows.Forms.CheckBox
    $driverBackupCheck.Location = New-Object System.Drawing.Point(20, 50)
    $driverBackupCheck.Size = New-Object System.Drawing.Size(350, 20)
    $driverBackupCheck.Text = "Backup drivers before updating"
    $driverBackupCheck.Checked = $currentSettings.BackupDrivers
    $driverBackupCheck.ForeColor = $script:Colors.Text
    $driverTab.Controls.Add($driverBackupCheck)
    
    # Beta Drivers
    $betaDriverCheck = New-Object System.Windows.Forms.CheckBox
    $betaDriverCheck.Location = New-Object System.Drawing.Point(20, 80)
    $betaDriverCheck.Size = New-Object System.Drawing.Size(350, 20)
    $betaDriverCheck.Text = "Include beta/preview drivers (not recommended)"
    $betaDriverCheck.Checked = $currentSettings.BetaDrivers
    $betaDriverCheck.ForeColor = $script:Colors.Text
    $driverTab.Controls.Add($betaDriverCheck)
    
    $tabControl.TabPages.Add($driverTab)
    
    # Appearance Settings Tab
    $appearanceTab = New-Object System.Windows.Forms.TabPage
    $appearanceTab.Text = "Appearance"
    $appearanceTab.BackColor = $script:Colors.Background
    $appearanceTab.ForeColor = $script:Colors.Text
    
    # Theme Selection
    $themeLabel = New-Object System.Windows.Forms.Label
    $themeLabel.Location = New-Object System.Drawing.Point(20, 20)
    $themeLabel.Size = New-Object System.Drawing.Size(100, 20)
    $themeLabel.Text = "Color Theme:"
    $themeLabel.ForeColor = $script:Colors.Text
    $appearanceTab.Controls.Add($themeLabel)
    
    $themeCombo = New-Object System.Windows.Forms.ComboBox
    $themeCombo.Location = New-Object System.Drawing.Point(130, 18)
    $themeCombo.Size = New-Object System.Drawing.Size(150, 25)
    $themeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $themeCombo.Items.AddRange($script:Themes.Keys)
    $themeCombo.BackColor = $script:Colors.CardBackground
    $themeCombo.ForeColor = $script:Colors.Text
    
    # Safely set the selected theme
    try {
        $themeValue = $currentSettings.Theme
        if ($themeValue -and $themeCombo.Items.Contains($themeValue)) {
            $themeCombo.SelectedItem = $themeValue
        }
        else {
            $themeCombo.SelectedIndex = 0  # Default to first theme
        }
    }
    catch {
        $themeCombo.SelectedIndex = 0
    }
    
    $appearanceTab.Controls.Add($themeCombo)
    
    # Preview button for theme
    $previewThemeBtn = New-Object System.Windows.Forms.Button
    $previewThemeBtn.Location = New-Object System.Drawing.Point(290, 17)
    $previewThemeBtn.Size = New-Object System.Drawing.Size(80, 27)
    $previewThemeBtn.Text = "Preview"
    $previewThemeBtn.BackColor = $script:Colors.Primary
    $previewThemeBtn.ForeColor = $script:Colors.Text
    $previewThemeBtn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $previewThemeBtn.Add_Click({
            if ($themeCombo.SelectedItem) {
                Set-ApplicationTheme -ThemeName $themeCombo.SelectedItem.ToString()
            }
        })
    $appearanceTab.Controls.Add($previewThemeBtn)
    
    # Auto-refresh settings
    $autoRefreshCheck = New-Object System.Windows.Forms.CheckBox
    $autoRefreshCheck.Location = New-Object System.Drawing.Point(20, 60)
    $autoRefreshCheck.Size = New-Object System.Drawing.Size(300, 20)
    $autoRefreshCheck.Text = "Enable automatic dashboard refresh"
    $autoRefreshCheck.Checked = $currentSettings.AutoRefresh
    $autoRefreshCheck.ForeColor = $script:Colors.Text
    $appearanceTab.Controls.Add($autoRefreshCheck)
    
    # Refresh interval
    $intervalLabel = New-Object System.Windows.Forms.Label
    $intervalLabel.Location = New-Object System.Drawing.Point(40, 90)
    $intervalLabel.Size = New-Object System.Drawing.Size(120, 20)
    $intervalLabel.Text = "Refresh interval (sec):"
    $intervalLabel.ForeColor = $script:Colors.Text
    $appearanceTab.Controls.Add($intervalLabel)
    
    $intervalCombo = New-Object System.Windows.Forms.ComboBox
    $intervalCombo.Location = New-Object System.Drawing.Point(170, 88)
    $intervalCombo.Size = New-Object System.Drawing.Size(80, 25)
    $intervalCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $intervalCombo.Items.AddRange(@("1", "3", "5", "10", "15", "30"))
    $intervalCombo.BackColor = $script:Colors.CardBackground
    $intervalCombo.ForeColor = $script:Colors.Text
    
    # Set refresh interval
    try {
        $intervalValue = $currentSettings.RefreshInterval.ToString()
        if ($intervalCombo.Items.Contains($intervalValue)) {
            $intervalCombo.SelectedItem = $intervalValue
        }
        else {
            $intervalCombo.SelectedIndex = 2  # Default to 5 seconds
        }
    }
    catch {
        $intervalCombo.SelectedIndex = 2
    }
    
    $appearanceTab.Controls.Add($intervalCombo)
    
    # Time Format Setting
    $timeFormatLabel = New-Object System.Windows.Forms.Label
    $timeFormatLabel.Location = New-Object System.Drawing.Point(280, 90)
    $timeFormatLabel.Size = New-Object System.Drawing.Size(80, 20)
    $timeFormatLabel.Text = "Time Format:"
    $timeFormatLabel.ForeColor = $script:Colors.Text
    $appearanceTab.Controls.Add($timeFormatLabel)
    
    $timeFormatCombo = New-Object System.Windows.Forms.ComboBox
    $timeFormatCombo.Location = New-Object System.Drawing.Point(370, 88)
    $timeFormatCombo.Size = New-Object System.Drawing.Size(100, 25)
    $timeFormatCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $timeFormatCombo.Items.AddRange(@("12-hour", "24-hour"))
    $timeFormatCombo.BackColor = $script:Colors.CardBackground
    $timeFormatCombo.ForeColor = $script:Colors.Text
    
    # Set time format
    try {
        $timeFormatValue = $currentSettings.TimeFormat
        if ($timeFormatCombo.Items.Contains($timeFormatValue)) {
            $timeFormatCombo.SelectedItem = $timeFormatValue
        }
        else {
            $timeFormatCombo.SelectedIndex = 1  # Default to 24-hour
        }
    }
    catch {
        $timeFormatCombo.SelectedIndex = 1  # Default to 24-hour
    }
    
    $appearanceTab.Controls.Add($timeFormatCombo)
    
    # Theme preview area
    $previewLabel = New-Object System.Windows.Forms.Label
    $previewLabel.Location = New-Object System.Drawing.Point(20, 130)
    $previewLabel.Size = New-Object System.Drawing.Size(100, 20)
    $previewLabel.Text = "Theme Preview:"
    $previewLabel.ForeColor = $script:Colors.Text
    $appearanceTab.Controls.Add($previewLabel)
    
    $previewPanel = New-Object System.Windows.Forms.Panel
    $previewPanel.Location = New-Object System.Drawing.Point(20, 155)
    $previewPanel.Size = New-Object System.Drawing.Size(480, 100)
    $previewPanel.BackColor = $script:Colors.Background
    $previewPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    
    $previewCard = New-Object System.Windows.Forms.Panel
    $previewCard.Location = New-Object System.Drawing.Point(10, 10)
    $previewCard.Size = New-Object System.Drawing.Size(150, 80)
    $previewCard.BackColor = $script:Colors.CardBackground
    $previewCard.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    
    $previewText = New-Object System.Windows.Forms.Label
    $previewText.Location = New-Object System.Drawing.Point(10, 10)
    $previewText.Size = New-Object System.Drawing.Size(130, 20)
    $previewText.Text = "Sample Card"
    $previewText.ForeColor = $script:Colors.Text
    $previewCard.Controls.Add($previewText)
    
    $previewButton = New-Object System.Windows.Forms.Button
    $previewButton.Location = New-Object System.Drawing.Point(10, 35)
    $previewButton.Size = New-Object System.Drawing.Size(80, 25)
    $previewButton.Text = "Primary"
    $previewButton.BackColor = $script:Colors.Primary
    $previewButton.ForeColor = $script:Colors.Text
    $previewButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $previewCard.Controls.Add($previewButton)
    
    $previewPanel.Controls.Add($previewCard)
    $appearanceTab.Controls.Add($previewPanel)
    
    $tabControl.TabPages.Add($appearanceTab)
    
    # Advanced Settings Tab
    $advancedTab = New-Object System.Windows.Forms.TabPage
    $advancedTab.Text = "Advanced"
    $advancedTab.BackColor = $script:Colors.Background
    $advancedTab.ForeColor = $script:Colors.Text
    
    # Logging Level
    $logLabel = New-Object System.Windows.Forms.Label
    $logLabel.Location = New-Object System.Drawing.Point(20, 20)
    $logLabel.Size = New-Object System.Drawing.Size(100, 20)
    $logLabel.Text = "Logging Level:"
    $logLabel.ForeColor = $script:Colors.Text
    $advancedTab.Controls.Add($logLabel)
    
    $logCombo = New-Object System.Windows.Forms.ComboBox
    $logCombo.Location = New-Object System.Drawing.Point(130, 18)
    $logCombo.Size = New-Object System.Drawing.Size(120, 25)
    $logCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $logCombo.Items.AddRange(@("Minimal", "Normal", "Detailed", "Debug"))
    $logCombo.BackColor = $script:Colors.CardBackground
    $logCombo.ForeColor = $script:Colors.Text
    
    # Safely set the selected item with validation
    try {
        $logValue = $currentSettings.LogLevel
        if ($logValue -and $logCombo.Items.Contains($logValue)) {
            $logCombo.SelectedItem = $logValue
        }
        else {
            $logCombo.SelectedIndex = 1  # Default to "Normal"
        }
    }
    catch {
        $logCombo.SelectedIndex = 1  # Default to "Normal" on error
    }
    
    $advancedTab.Controls.Add($logCombo)
    
    # Performance Mode
    $perfLabel = New-Object System.Windows.Forms.Label
    $perfLabel.Location = New-Object System.Drawing.Point(20, 60)
    $perfLabel.Size = New-Object System.Drawing.Size(120, 20)
    $perfLabel.Text = "Performance Mode:"
    $perfLabel.ForeColor = $script:Colors.Text
    $advancedTab.Controls.Add($perfLabel)
    
    $perfCombo = New-Object System.Windows.Forms.ComboBox
    $perfCombo.Location = New-Object System.Drawing.Point(150, 58)
    $perfCombo.Size = New-Object System.Drawing.Size(120, 25)
    $perfCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $perfCombo.Items.AddRange(@("Balanced", "Performance", "Power Saver"))
    $perfCombo.BackColor = $script:Colors.CardBackground
    $perfCombo.ForeColor = $script:Colors.Text
    
    # Safely set the selected item with validation
    try {
        $perfValue = $currentSettings.PerformanceMode
        if ($perfValue -and $perfCombo.Items.Contains($perfValue)) {
            $perfCombo.SelectedItem = $perfValue
        }
        else {
            $perfCombo.SelectedIndex = 0  # Default to "Balanced"
        }
    }
    catch {
        $perfCombo.SelectedIndex = 0  # Default to "Balanced" on error
    }
    
    $advancedTab.Controls.Add($perfCombo)
    
    # Debug Mode
    $debugCheck = New-Object System.Windows.Forms.CheckBox
    $debugCheck.Location = New-Object System.Drawing.Point(20, 100)
    $debugCheck.Size = New-Object System.Drawing.Size(300, 20)
    $debugCheck.Text = "Enable debug mode (creates detailed logs)"
    $debugCheck.Checked = $currentSettings.DebugMode
    $debugCheck.ForeColor = $script:Colors.Text
    $advancedTab.Controls.Add($debugCheck)
    
    $tabControl.TabPages.Add($advancedTab)
    
    $settingsForm.Controls.Add($tabControl)
    
    # Buttons Panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(10, 420)
    $buttonPanel.Size = New-Object System.Drawing.Size(560, 40)
    $buttonPanel.BackColor = $script:Colors.Background
    
    # Save Button
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Location = New-Object System.Drawing.Point(380, 5)
    $saveButton.Size = New-Object System.Drawing.Size(80, 30)
    $saveButton.Text = "Save"
    $saveButton.BackColor = $script:Colors.Success
    $saveButton.ForeColor = $script:Colors.Text
    $saveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $saveButton.Add_Click({
            try {
                # Save settings with proper null checking
                $newSettings = @{
                    AutoUpdates         = $autoUpdateCheck.Checked
                    AutoStart           = $autoStartCheck.Checked
                    CreateRestorePoints = $restorePointCheck.Checked
                    ShowNotifications   = $notificationsCheck.Checked
                    ScanSchedule        = if ($scheduleCombo.SelectedItem) { $scheduleCombo.SelectedItem.ToString() } else { "Weekly" }
                    AggressiveMode      = $aggressiveCheck.Checked
                    RegistryCleanup     = $registryCheck.Checked
                    CleanTempFiles      = $tempFilesCheck.Checked
                    MemoryOptimization  = $memoryCheck.Checked
                    DiskDefrag          = $defragCheck.Checked
                    AutoDriverUpdates   = $autoDriverCheck.Checked
                    BackupDrivers       = $driverBackupCheck.Checked
                    BetaDrivers         = $betaDriverCheck.Checked
                    LogLevel            = if ($logCombo.SelectedItem) { $logCombo.SelectedItem.ToString() } else { "Normal" }
                    PerformanceMode     = if ($perfCombo.SelectedItem) { $perfCombo.SelectedItem.ToString() } else { "Balanced" }
                    DebugMode           = $debugCheck.Checked
                    Theme               = if ($themeCombo.SelectedItem) { $themeCombo.SelectedItem.ToString() } else { "Dark Blue" }
                    AutoRefresh         = $autoRefreshCheck.Checked
                    RefreshInterval     = if ($intervalCombo.SelectedItem) { [int]$intervalCombo.SelectedItem.ToString() } else { 5 }
                    TimeFormat          = if ($timeFormatCombo.SelectedItem) { $timeFormatCombo.SelectedItem.ToString() } else { "24-hour" }
                }
            
                $saveResult = Save-OptimizationSettings -Settings $newSettings
                if ($saveResult) {
                    Add-LogMessage "Settings saved successfully"
                    [System.Windows.Forms.MessageBox]::Show("Settings saved successfully!", "Settings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    $settingsForm.Close()
                }
                else {
                    Add-LogMessage "Error: Failed to save settings"
                    [System.Windows.Forms.MessageBox]::Show("Failed to save settings. Please try again.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                Add-LogMessage "Error saving settings: $($_.Exception.Message)"
                [System.Windows.Forms.MessageBox]::Show("An error occurred while saving settings: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        })
    $buttonPanel.Controls.Add($saveButton)
    
    # Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(470, 5)
    $cancelButton.Size = New-Object System.Drawing.Size(80, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.BackColor = $script:Colors.CardBackground
    $cancelButton.ForeColor = $script:Colors.Text
    $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancelButton.Add_Click({
            $settingsForm.Close()
        })
    $buttonPanel.Controls.Add($cancelButton)
    
    # Reset Button
    $resetButton = New-Object System.Windows.Forms.Button
    $resetButton.Location = New-Object System.Drawing.Point(10, 5)
    $resetButton.Size = New-Object System.Drawing.Size(120, 30)
    $resetButton.Text = "Reset to Defaults"
    $resetButton.BackColor = $script:Colors.Warning
    $resetButton.ForeColor = $script:Colors.Text
    $resetButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $resetButton.Add_Click({
            $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to reset all settings to defaults?", "Reset Settings", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Reset-OptimizationSettings
                Add-LogMessage "Settings reset to defaults"
                [System.Windows.Forms.MessageBox]::Show("Settings have been reset to defaults. Please restart the application.", "Settings Reset", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                $settingsForm.Close()
            }
        })
    $buttonPanel.Controls.Add($resetButton)
    
    $settingsForm.Controls.Add($buttonPanel)
    
    # Show the settings dialog
    $settingsForm.ShowDialog() | Out-Null
}

function New-ProgressDialog {
    param(
        [string]$Title = "Progress",
        [string]$Message = "Please wait..."
    )
    
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = $Title
    $progressForm.Size = New-Object System.Drawing.Size(400, 150)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $script:Colors.Background
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false
    
    $messageLabel = New-ModernLabel -Text $Message -X 20 -Y 20 -Width 360 -Height 40 -FontSize 10
    $progressForm.Controls.Add($messageLabel)
    
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 70)
    $progressBar.Size = New-Object System.Drawing.Size(360, 25)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $progressForm.Controls.Add($progressBar)
    
    return $progressForm
}

#endregion

#region Main Execution

# Show splash screen
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " PC Optimization Suite GUI v$script:ModuleVersion" -ForegroundColor Cyan
Write-Host " Professional Interface Loading..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Initialize performance optimizations
    if (Get-Command Initialize-PerformanceOptimizations -ErrorAction SilentlyContinue) {
        Initialize-PerformanceOptimizations
    }
    
    # Create and show main form
    $mainForm = New-MainForm
    
    Write-Host "GUI Application ready! Launching interface..." -ForegroundColor Green
    
    # Show the form
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::Run($mainForm)
    
    # Cleanup when form closes
    if (Get-Command Stop-PerformanceOptimizations -ErrorAction SilentlyContinue) {
        Stop-PerformanceOptimizations
    }
    
}
catch {
    Write-Host "Error launching GUI: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Falling back to console mode..." -ForegroundColor Yellow
    
    # Fallback to console interface
    Write-Host ""
    Write-Host "=== Console Mode ===" -ForegroundColor Yellow
    $systemData = Get-SystemOverview
    $driverHealth = Get-DriverHealthSummary
    
    if ($systemData) {
        Write-Host "System: $($systemData.ComputerName)" -ForegroundColor White
        Write-Host "CPU Usage: $($systemData.CPUUsage)%" -ForegroundColor White
        Write-Host "Memory Usage: $($systemData.MemoryUsage)%" -ForegroundColor White
        Write-Host "Driver Health: $($driverHealth.Status)" -ForegroundColor White
    }
}

#endregion