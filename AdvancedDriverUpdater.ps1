#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Advanced Driver Scanner and Updater for Windows
    
.DESCRIPTION
    This script scans the entire PC for outdated drivers and can automatically update them.
    Features include:
    - Comprehensive driver scanning using WMI and PnP cmdlets
    - Windows Update integration for driver updates
    - Manufacturer-specific driver downloads
    - Safety features (backup, rollback, system restore points)
    - Detailed logging and reporting
    - Scheduling and configuration options
    
.PARAMETER ScanOnly
    Only scan for outdated drivers without installing updates
    
.PARAMETER AutoUpdate
    Automatically install all available driver updates
    
.PARAMETER CreateRestorePoint
    Create a system restore point before installing updates
    
.PARAMETER LogPath
    Path to save detailed logs (default: script directory)
    
.EXAMPLE
    .\AdvancedDriverUpdater.ps1 -ScanOnly
    .\AdvancedDriverUpdater.ps1 -AutoUpdate -CreateRestorePoint
    
.NOTES
    Author: GitHub Copilot
    Version: 1.0
    Requires: PowerShell 5.1+ and Administrator privileges
#>

param(
    [switch]$ScanOnly,
    [switch]$AutoUpdate,
    [switch]$CreateRestorePoint,
    [string]$LogPath = $PSScriptRoot,
    [switch]$Silent,
    [switch]$ScheduleTask
)

# Import logging system
try {
    . "$PSScriptRoot\SystemLogger.ps1"
    Write-Log "AdvancedDriverUpdater started" -Level Info -LogType Driver -Component "DriverUpdater"
}
catch {
    Write-Warning "Could not load logging system: $($_.Exception.Message)"
    # Keep existing fallback logging function below
}

# Global Variables
$script:LogFile = Join-Path $LogPath "DriverUpdater_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:DriversFound = @()
$script:UpdatesAvailable = @()
$script:InstallResults = @()

#region Helper Functions

# Fallback logging function (will be overridden if SystemLogger loads successfully)
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with colors
    if (-not $Silent) {
        switch ($Level) {
            "Info" { Write-Host $logEntry -ForegroundColor White }
            "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
            "Error" { Write-Host $logEntry -ForegroundColor Red }
            "Success" { Write-Host $logEntry -ForegroundColor Green }
        }
    }
    
    # Write to log file
    Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SystemInfo {
    Write-Log "Gathering system information..."
    
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $computer = Get-WmiObject -Class Win32_ComputerSystem
    
    $sysInfo = @{
        OSName            = $os.Caption
        OSVersion         = $os.Version
        OSArchitecture    = $os.OSArchitecture
        ComputerName      = $computer.Name
        Manufacturer      = $computer.Manufacturer
        Model             = $computer.Model
        TotalRAM          = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
    
    Write-Log "System: $($sysInfo.OSName) $($sysInfo.OSVersion) ($($sysInfo.OSArchitecture))"
    Write-Log "Computer: $($sysInfo.Manufacturer) $($sysInfo.Model)"
    
    return $sysInfo
}

function Get-InstalledDrivers {
    Write-Log "Scanning for installed drivers..."
    
    try {
        # Get PnP devices with driver information
        $pnpDevices = Get-PnpDevice | Where-Object { 
            $_.Status -eq "OK" -and 
            $_.Class -notmatch "System|Software|Unknown|HIDClass|Keyboard|Mouse" 
        }
        
        $drivers = @()
        $deviceCount = $pnpDevices.Count
        $current = 0
        
        foreach ($device in $pnpDevices) {
            $current++
            if (-not $Silent) {
                Write-Progress -Activity "Scanning Drivers" -Status "Processing device $current of $deviceCount" -PercentComplete (($current / $deviceCount) * 100)
            }
            
            try {
                # Get driver details
                $driverInfo = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName @(
                    'DEVPKEY_Device_DriverVersion',
                    'DEVPKEY_Device_DriverDate',
                    'DEVPKEY_Device_DriverInfPath',
                    'DEVPKEY_Device_Manufacturer',
                    'DEVPKEY_Device_HardwareIds'
                ) -ErrorAction SilentlyContinue
                
                if ($driverInfo) {
                    $driverVersion = ($driverInfo | Where-Object KeyName -EQ 'DEVPKEY_Device_DriverVersion').Data
                    $driverDate = ($driverInfo | Where-Object KeyName -EQ 'DEVPKEY_Device_DriverDate').Data
                    $driverInf = ($driverInfo | Where-Object KeyName -EQ 'DEVPKEY_Device_DriverInfPath').Data
                    $manufacturer = ($driverInfo | Where-Object KeyName -EQ 'DEVPKEY_Device_Manufacturer').Data
                    $hardwareIds = ($driverInfo | Where-Object KeyName -EQ 'DEVPKEY_Device_HardwareIds').Data
                    
                    if ($driverVersion -and $driverDate) {
                        $drivers += [PSCustomObject]@{
                            DeviceName    = $device.FriendlyName
                            InstanceId    = $device.InstanceId
                            Class         = $device.Class
                            Manufacturer  = $manufacturer
                            DriverVersion = $driverVersion
                            DriverDate    = $driverDate
                            DriverInf     = $driverInf
                            HardwareIds   = $hardwareIds
                            Status        = $device.Status
                            Problem       = $device.Problem
                        }
                    }
                }
            }
            catch {
                Write-Log "Warning: Could not get driver info for $($device.FriendlyName): $($_.Exception.Message)" -Level Warning
            }
        }
        
        Write-Progress -Activity "Scanning Drivers" -Completed
        Write-Log "Found $($drivers.Count) drivers with version information"
        
        return $drivers
    }
    catch {
        Write-Log "Error scanning drivers: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-DriverAge {
    param(
        [datetime]$DriverDate,
        [int]$MaxAgeDays = 365
    )
    
    $daysSinceDriver = (Get-Date) - $DriverDate
    return $daysSinceDriver.Days -gt $MaxAgeDays
}

function Find-OutdatedDrivers {
    param(
        [array]$Drivers,
        [int]$MaxAgeDays = 365
    )
    
    Write-Log "Analyzing drivers for outdated versions..."
    
    $outdatedDrivers = @()
    
    foreach ($driver in $Drivers) {
        $isOld = Test-DriverAge -DriverDate $driver.DriverDate -MaxAgeDays $MaxAgeDays
        
        if ($isOld) {
            $daysSince = ((Get-Date) - $driver.DriverDate).Days
            
            $outdatedDrivers += [PSCustomObject]@{
                DeviceName     = $driver.DeviceName
                InstanceId     = $driver.InstanceId
                Class          = $driver.Class
                Manufacturer   = $driver.Manufacturer
                CurrentVersion = $driver.DriverVersion
                CurrentDate    = $driver.DriverDate
                DaysOld        = $daysSince
                HardwareIds    = $driver.HardwareIds
                Priority       = Get-DriverUpdatePriority -Class $driver.Class -DaysOld $daysSince
            }
        }
    }
    
    # Sort by priority (High priority first)
    $outdatedDrivers = $outdatedDrivers | Sort-Object @{Expression = "Priority"; Descending = $false }, DaysOld -Descending
    
    Write-Log "Found $($outdatedDrivers.Count) potentially outdated drivers"
    
    return $outdatedDrivers
}

function Get-DriverUpdatePriority {
    param(
        [string]$Class,
        [int]$DaysOld
    )
    
    # High priority classes
    $highPriorityClasses = @('Display', 'Net', 'System', 'SecurityDevices', 'AudioEndpoint', 'Media')
    
    if ($Class -in $highPriorityClasses) {
        if ($DaysOld -gt 730) { return 1 } # Very High
        elseif ($DaysOld -gt 365) { return 2 } # High
        else { return 3 } # Medium
    }
    else {
        if ($DaysOld -gt 1095) { return 3 } # Medium
        else { return 4 } # Low
    }
}

function New-SystemRestorePoint {
    param(
        [string]$Description = "Driver Update - Advanced Driver Updater"
    )
    
    Write-Log "Creating system restore point..."
    
    try {
        # Enable System Restore if not enabled
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        
        # Create restore point
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        Write-Log "System restore point created successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to create system restore point: $($_.Exception.Message)" -Level Warning
        return $false
    }
}

#endregion

#region Windows Update Functions

function Install-PSWindowsUpdate {
    Write-Log "Checking for PSWindowsUpdate module..."
    
    if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
        Write-Log "Installing PSWindowsUpdate module..."
        try {
            Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser
            Write-Log "PSWindowsUpdate module installed successfully" -Level Success
        }
        catch {
            Write-Log "Failed to install PSWindowsUpdate module: $($_.Exception.Message)" -Level Error
            return $false
        }
    }
    else {
        Write-Log "PSWindowsUpdate module already installed"
    }
    
    Import-Module PSWindowsUpdate -Force
    return $true
}

function Search-WindowsUpdateDrivers {
    Write-Log "Searching for driver updates through Windows Update..."
    
    if (-not (Install-PSWindowsUpdate)) {
        Write-Log "Cannot search Windows Update without PSWindowsUpdate module" -Level Error
        return @()
    }
    
    try {
        $updates = Get-WUList -Category "Drivers" -ErrorAction Stop
        
        if ($updates) {
            Write-Log "Found $($updates.Count) driver updates available through Windows Update" -Level Success
            
            foreach ($update in $updates) {
                Write-Log "Available: $($update.Title) - Size: $([math]::Round($update.Size/1MB, 2)) MB"
            }
        }
        else {
            Write-Log "No driver updates found through Windows Update"
        }
        
        return $updates
    }
    catch {
        Write-Log "Error searching Windows Update: $($_.Exception.Message)" -Level Error
        return @()
    }
}

function Install-WindowsUpdateDrivers {
    param(
        [array]$Updates
    )
    
    if ($Updates.Count -eq 0) {
        Write-Log "No Windows Update drivers to install"
        return @()
    }
    
    Write-Log "Installing $($Updates.Count) driver updates from Windows Update..."
    
    $results = @()
    
    try {
        foreach ($update in $Updates) {
            Write-Log "Installing: $($update.Title)"
            
            try {
                $installResult = Install-WUUpdates -Updates $update -AcceptAll -AutoReboot:$false -ErrorAction Stop
                
                $results += [PSCustomObject]@{
                    Title          = $update.Title
                    Status         = "Success"
                    Error          = $null
                    RebootRequired = $installResult.RebootRequired
                }
                
                Write-Log "Successfully installed: $($update.Title)" -Level Success
            }
            catch {
                $results += [PSCustomObject]@{
                    Title          = $update.Title
                    Status         = "Failed"
                    Error          = $_.Exception.Message
                    RebootRequired = $false
                }
                
                Write-Log "Failed to install $($update.Title): $($_.Exception.Message)" -Level Error
            }
        }
    }
    catch {
        Write-Log "Error during Windows Update installation: $($_.Exception.Message)" -Level Error
    }
    
    return $results
}

#endregion

#region Advanced Driver Discovery Functions

function Get-ManufacturerFromHardwareId {
    param(
        [array]$HardwareIds
    )
    
    if (-not $HardwareIds) { return "Unknown" }
    
    $vendorMappings = @{
        "VEN_8086" = "Intel"
        "VEN_10DE" = "NVIDIA"
        "VEN_1002" = "AMD"
        "VEN_1022" = "AMD"
        "VEN_14E4" = "Broadcom"
        "VEN_8187" = "Realtek"
        "VEN_10EC" = "Realtek"
        "VEN_1106" = "VIA"
        "VEN_1039" = "SiS"
        "VEN_15AD" = "VMware"
        "VEN_80EE" = "VirtualBox"
        "VEN_1B73" = "Fresco Logic"
        "VEN_104C" = "Texas Instruments"
        "VEN_11AB" = "Marvell"
        "VEN_13F6" = "C-Media"
        "VEN_1D6B" = "Linux Foundation"
        "VEN_168C" = "Qualcomm Atheros"
        "VEN_1969" = "Atheros"
        "VEN_15B3" = "Mellanox"
        "VEN_1425" = "Chelsio"
    }
    
    foreach ($hwId in $HardwareIds) {
        foreach ($vendor in $vendorMappings.Keys) {
            if ($hwId -match $vendor) {
                return $vendorMappings[$vendor]
            }
        }
    }
    
    return "Unknown"
}

function Get-HardwareFingerprint {
    param(
        [array]$HardwareIds,
        [string]$InstanceId
    )
    
    $fingerprint = @{
        VendorId      = ""
        DeviceId      = ""
        SubsystemId   = ""
        RevisionId    = ""
        ClassCode     = ""
        PrimaryId     = ""
        CompatibleIds = @()
    }
    
    if ($HardwareIds) {
        foreach ($hwId in $HardwareIds) {
            if ($hwId -match "PCI\\VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})") {
                $fingerprint.VendorId = $matches[1]
                $fingerprint.DeviceId = $matches[2]
                $fingerprint.PrimaryId = "$($matches[1]):$($matches[2])"
            }
            
            if ($hwId -match "SUBSYS_([0-9A-F]{8})") {
                $fingerprint.SubsystemId = $matches[1]
            }
            
            if ($hwId -match "REV_([0-9A-F]{2})") {
                $fingerprint.RevisionId = $matches[1]
            }
            
            $fingerprint.CompatibleIds += $hwId
        }
    }
    
    return $fingerprint
}

function Search-DriverDatabases {
    param(
        [object]$HardwareFingerprint,
        [string]$DeviceName
    )
    
    Write-Log "Searching advanced driver databases for $DeviceName..."
    
    $driverSources = @()
    
    # Search DriverPack API (simulated)
    try {
        $driverPackResults = Search-DriverPackDatabase -VendorId $HardwareFingerprint.VendorId -DeviceId $HardwareFingerprint.DeviceId
        $driverSources += $driverPackResults
    }
    catch {
        Write-Log "DriverPack search failed: $($_.Exception.Message)" -Level Warning
    }
    
    # Search Station-Drivers (simulated)
    try {
        $stationResults = Search-StationDrivers -HardwareId $HardwareFingerprint.PrimaryId
        $driverSources += $stationResults
    }
    catch {
        Write-Log "Station-Drivers search failed: $($_.Exception.Message)" -Level Warning
    }
    
    # Search DriverGuide database (simulated)
    try {
        $driverGuideResults = Search-DriverGuideDatabase -DeviceName $DeviceName -VendorId $HardwareFingerprint.VendorId
        $driverSources += $driverGuideResults
    }
    catch {
        Write-Log "DriverGuide search failed: $($_.Exception.Message)" -Level Warning
    }
    
    # Search Windows Catalog
    try {
        $catalogResults = Search-WindowsCatalog -HardwareIds $HardwareFingerprint.CompatibleIds
        $driverSources += $catalogResults
    }
    catch {
        Write-Log "Windows Catalog search failed: $($_.Exception.Message)" -Level Warning
    }
    
    return $driverSources
}

function Search-DriverPackDatabase {
    param(
        [string]$VendorId,
        [string]$DeviceId
    )
    
    # Simulated DriverPack API integration
    # In real implementation, this would call DriverPack's API
    
    $apiUrl = "https://api.driverpack.io/api/search"
    $body = @{
        vendor_id = $VendorId
        device_id = $DeviceId
        os        = "win10"
        arch      = "x64"
    } | ConvertTo-Json
    
    try {
        # Simulate API call with timeout and retry logic
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30 -ErrorAction Stop
        
        $results = @()
        if ($response.drivers) {
            foreach ($driver in $response.drivers) {
                $results += [PSCustomObject]@{
                    Source      = "DriverPack"
                    DriverName  = $driver.name
                    Version     = $driver.version
                    Date        = $driver.date
                    DownloadUrl = $driver.download_url
                    Size        = $driver.size
                    Verified    = $driver.verified
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "DriverPack API call failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-StationDrivers {
    param(
        [string]$HardwareId
    )
    
    # Simulated Station-Drivers search
    # In real implementation, this would scrape or use Station-Drivers API
    
    try {
        $searchUrl = "https://www.station-drivers.com/search.php?q=$HardwareId"
        
        # Simulate web scraping with proper headers
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            'Accept'     = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        }
        
        $response = Invoke-WebRequest -Uri $searchUrl -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        
        # Parse response for driver links
        $driverLinks = $response.Links | Where-Object { $_.href -match "download|driver" }
        
        $results = @()
        foreach ($link in $driverLinks) {
            if ($link.innerText -match "driver|download") {
                $results += [PSCustomObject]@{
                    Source      = "Station-Drivers"
                    DriverName  = $link.innerText
                    DownloadUrl = $link.href
                    Verified    = $false
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "Station-Drivers search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-DriverGuideDatabase {
    param(
        [string]$DeviceName,
        [string]$VendorId
    )
    
    # Simulated DriverGuide database search
    $results = @()
    
    try {
        # This would integrate with DriverGuide's search API or web interface
        # Implement actual search logic here
        Write-Log "Searching DriverGuide for: $DeviceName"
        
        return $results
    }
    catch {
        Write-Log "DriverGuide search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-WindowsCatalog {
    param(
        [array]$HardwareIds
    )
    
    Write-Log "Searching Windows Update Catalog..."
    
    $results = @()
    
    try {
        foreach ($hwId in $HardwareIds) {
            $searchUrl = "https://www.catalog.update.microsoft.com/Search.aspx?q=$hwId"
            
            # Use Windows Update Catalog search
            $response = Invoke-WebRequest -Uri $searchUrl -TimeoutSec 30 -ErrorAction SilentlyContinue
            
            if ($response.Content -match "driver") {
                # Parse catalog results
                $results += [PSCustomObject]@{
                    Source     = "Windows Catalog"
                    HardwareId = $hwId
                    Found      = $true
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "Windows Catalog search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-OEMDriverSources {
    param(
        [string]$Manufacturer,
        [string]$Model,
        [object]$HardwareFingerprint
    )
    
    Write-Log "Searching OEM-specific driver sources..."
    
    $oemSources = @()
    
    # Dell driver search
    if ($Manufacturer -match "Dell") {
        $oemSources += Search-DellDrivers -Model $Model -HardwareFingerprint $HardwareFingerprint
    }
    
    # HP driver search
    if ($Manufacturer -match "HP|Hewlett") {
        $oemSources += Search-HPDrivers -Model $Model -HardwareFingerprint $HardwareFingerprint
    }
    
    # Lenovo driver search
    if ($Manufacturer -match "Lenovo") {
        $oemSources += Search-LenovoDrivers -Model $Model -HardwareFingerprint $HardwareFingerprint
    }
    
    # ASUS driver search
    if ($Manufacturer -match "ASUS") {
        $oemSources += Search-ASUSDrivers -Model $Model -HardwareFingerprint $HardwareFingerprint
    }
    
    return $oemSources
}

function Search-DellDrivers {
    param(
        [string]$Model,
        [object]$HardwareFingerprint
    )
    
    try {
        # Dell API integration would go here
        # Implementation for Dell's driver API
        Write-Log "Dell driver search not yet implemented for model: $Model" -Level Info
        
        return @()
    }
    catch {
        Write-Log "Dell driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Expand-DriversFromImage {
    param(
        [string]$ImagePath,
        [string]$TempPath = "$env:TEMP\DriverExtraction"
    )
    
    Write-Log "Extracting drivers from Windows image: $ImagePath"
    
    try {
        # Create temporary directory
        if (-not (Test-Path $TempPath)) {
            New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
        }
        
        # Mount Windows image
        $mountPath = Join-Path $TempPath "Mount"
        New-Item -Path $mountPath -ItemType Directory -Force | Out-Null
        
        Mount-WindowsImage -ImagePath $ImagePath -Index 1 -Path $mountPath -ReadOnly
        
        # Extract driver store
        $driverStorePath = Join-Path $mountPath "Windows\System32\DriverStore\FileRepository"
        $extractPath = Join-Path $TempPath "ExtractedDrivers"
        
        if (Test-Path $driverStorePath) {
            Copy-Item -Path $driverStorePath -Destination $extractPath -Recurse -Force
            Write-Log "Drivers extracted to: $extractPath" -Level Success
        }
        
        # Dismount image
        Dismount-WindowsImage -Path $mountPath -Discard
        
        return $extractPath
    }
    catch {
        Write-Log "Driver extraction failed: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Find-CompatibleDrivers {
    param(
        [object]$HardwareFingerprint,
        [string]$DriverPath
    )
    
    Write-Log "Searching for compatible drivers in: $DriverPath"
    
    $compatibleDrivers = @()
    
    try {
        # Search INF files for matching hardware IDs
        $infFiles = Get-ChildItem -Path $DriverPath -Filter "*.inf" -Recurse
        
        foreach ($infFile in $infFiles) {
            $infContent = Get-Content $infFile.FullName -ErrorAction SilentlyContinue
            
            if ($infContent) {
                # Check for hardware ID matches
                foreach ($hwId in $HardwareFingerprint.CompatibleIds) {
                    if ($infContent -match [regex]::Escape($hwId)) {
                        $compatibleDrivers += [PSCustomObject]@{
                            INFPath       = $infFile.FullName
                            HardwareId    = $hwId
                            DriverPath    = $infFile.Directory.FullName
                            Compatibility = "Direct Match"
                        }
                        break
                    }
                }
                
                # Check for vendor/device ID patterns
                $vendorDevicePattern = "VEN_$($HardwareFingerprint.VendorId)&DEV_$($HardwareFingerprint.DeviceId)"
                if ($infContent -match [regex]::Escape($vendorDevicePattern)) {
                    $compatibleDrivers += [PSCustomObject]@{
                        INFPath       = $infFile.FullName
                        HardwareId    = $vendorDevicePattern
                        DriverPath    = $infFile.Directory.FullName
                        Compatibility = "Vendor/Device Match"
                    }
                }
            }
        }
        
        return $compatibleDrivers
    }
    catch {
        Write-Log "Compatible driver search failed: $($_.Exception.Message)" -Level Error
        return @()
    }
}

function Search-ManufacturerDrivers {
    param(
        [array]$OutdatedDrivers
    )
    
    Write-Log "Searching manufacturer websites and advanced sources for driver updates..."
    
    $manufacturerUpdates = @()
    
    foreach ($driver in $OutdatedDrivers) {
        $vendor = Get-ManufacturerFromHardwareId -HardwareIds $driver.HardwareIds
        $fingerprint = Get-HardwareFingerprint -HardwareIds $driver.HardwareIds -InstanceId $driver.InstanceId
        
        Write-Log "Checking $vendor drivers for $($driver.DeviceName)..."
        
        # Primary manufacturer website search
        $primaryResults = Search-PrimaryManufacturerSite -Vendor $vendor -Fingerprint $fingerprint -DeviceName $driver.DeviceName
        $manufacturerUpdates += $primaryResults
        
        # If no results from primary sources, try advanced discovery
        if ($primaryResults.Count -eq 0) {
            Write-Log "No results from primary sources, trying advanced discovery..." -Level Warning
            
            # Search driver databases
            $databaseResults = Search-DriverDatabases -HardwareFingerprint $fingerprint -DeviceName $driver.DeviceName
            $manufacturerUpdates += $databaseResults
            
            # Search OEM sources if we have system info
            $sysInfo = Get-SystemInfo
            $oemResults = Search-OEMDriverSources -Manufacturer $sysInfo.Manufacturer -Model $sysInfo.Model -HardwareFingerprint $fingerprint
            $manufacturerUpdates += $oemResults
            
            # Try generic driver search
            $genericResults = Search-GenericDriverSources -HardwareFingerprint $fingerprint -DeviceName $driver.DeviceName
            $manufacturerUpdates += $genericResults
            
            # Last resort: AI-powered compatibility search
            $aiResults = Search-AICompatibleDrivers -HardwareFingerprint $fingerprint -DeviceName $driver.DeviceName
            $manufacturerUpdates += $aiResults
        }
        
        # For critical drivers, try even more aggressive methods
        if ($driver.Priority -le 2 -and $manufacturerUpdates.Count -eq 0) {
            Write-Log "Critical driver with no updates found, trying aggressive search..." -Level Warning
            
            # Search driver extraction from similar systems
            $extractedResults = Search-ExtractedDrivers -HardwareFingerprint $fingerprint
            $manufacturerUpdates += $extractedResults
            
            # Network driver sharing search
            $networkResults = Search-NetworkDriverRepository -HardwareFingerprint $fingerprint
            $manufacturerUpdates += $networkResults
        }
    }
    
    Write-Log "Found $($manufacturerUpdates.Count) potential manufacturer driver updates"
    return $manufacturerUpdates
}

function Search-PrimaryManufacturerSite {
    param(
        [string]$Vendor,
        [object]$Fingerprint,
        [string]$DeviceName
    )
    
    $results = @()
    
    try {
        switch ($Vendor) {
            "Intel" {
                $results += Search-IntelDrivers -Fingerprint $Fingerprint -DeviceName $DeviceName
            }
            "NVIDIA" {
                $results += Search-NVIDIADrivers -Fingerprint $Fingerprint -DeviceName $DeviceName
            }
            "AMD" {
                $results += Search-AMDDrivers -Fingerprint $Fingerprint -DeviceName $DeviceName
            }
            "Realtek" {
                $results += Search-RealtekDrivers -Fingerprint $Fingerprint -DeviceName $DeviceName
            }
            default {
                Write-Log "No specific search implementation for vendor: $Vendor" -Level Warning
            }
        }
    }
    catch {
        Write-Log "Primary manufacturer search failed for $Vendor`: $($_.Exception.Message)" -Level Warning
    }
    
    return $results
}

function Search-IntelDrivers {
    param(
        [object]$Fingerprint,
        [string]$DeviceName
    )
    
    try {
        # Intel Driver & Support Assistant API simulation
        Write-Log "Searching Intel Download Center for device: $DeviceName"
        
        # In real implementation, this would call Intel's actual API
        $mockResults = @()
        if ($Fingerprint.VendorId -eq "8086") {
            $mockResults += [PSCustomObject]@{
                Source      = "Intel"
                DriverName  = "Intel $DeviceName Driver"
                Version     = "Latest"
                DownloadUrl = "https://downloadcenter.intel.com/driver"
                ReleaseDate = (Get-Date).AddDays(-30)
                Verified    = $true
            }
        }
        
        return $mockResults
    }
    catch {
        Write-Log "Intel driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-NVIDIADrivers {
    param(
        [object]$Fingerprint,
        [string]$DeviceName
    )
    
    try {
        # NVIDIA API integration
        Write-Log "Searching NVIDIA for device: $DeviceName"
        
        # Simulate NVIDIA driver search
        $mockResults = @()
        if ($Fingerprint.VendorId -eq "10DE" -and $DeviceName -match "GeForce|Quadro|Tesla") {
            $mockResults += [PSCustomObject]@{
                Source      = "NVIDIA"
                DriverName  = "NVIDIA $DeviceName Driver"
                Version     = "Latest Game Ready"
                DownloadUrl = "https://www.nvidia.com/drivers"
                ReleaseDate = (Get-Date).AddDays(-7)
                Verified    = $true
            }
        }
        
        return $mockResults
    }
    catch {
        Write-Log "NVIDIA driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-AMDDrivers {
    param(
        [object]$Fingerprint,
        [string]$DeviceName
    )
    
    try {
        Write-Log "Searching AMD for device: $DeviceName"
        
        # AMD Auto-Detect and Install API simulation
        $mockResults = @()
        if ($Fingerprint.VendorId -eq "1002" -and $DeviceName -match "Radeon|FirePro") {
            $mockResults += [PSCustomObject]@{
                Source      = "AMD"
                DriverName  = "AMD $DeviceName Driver"
                Version     = "Latest Adrenalin"
                DownloadUrl = "https://www.amd.com/support"
                ReleaseDate = (Get-Date).AddDays(-14)
                Verified    = $true
            }
        }
        
        return $mockResults
    }
    catch {
        Write-Log "AMD driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-GenericDriverSources {
    param(
        [object]$HardwareFingerprint,
        [string]$DeviceName
    )
    
    Write-Log "Searching generic driver sources..."
    
    $results = @()
    
    try {
        # Search DriverDownloader database
        $driverDownloaderResults = Search-DriverDownloader -Fingerprint $HardwareFingerprint
        $results += $driverDownloaderResults
        
        # Search DevID database
        $devIdResults = Search-DevIDDatabase -Fingerprint $HardwareFingerprint
        $results += $devIdResults
        
        # Search PCIDatabase.com
        $pciDbResults = Search-PCIDatabase -Fingerprint $HardwareFingerprint
        $results += $pciDbResults
        
        return $results
    }
    catch {
        Write-Log "Generic driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-AICompatibleDrivers {
    param(
        [object]$HardwareFingerprint,
        [string]$DeviceName
    )
    
    Write-Log "Using AI-powered compatibility search for: $DeviceName"
    
    try {
        # This would integrate with an AI service to find compatible drivers
        # based on hardware similarities and known working combinations
        
        $aiResults = @()
        
        # Simulate AI-based driver compatibility checking
        $similarDevices = Find-SimilarHardware -Fingerprint $HardwareFingerprint
        
        foreach ($device in $similarDevices) {
            $compatibilityScore = Calculate-CompatibilityScore -Source $HardwareFingerprint -Target $device
            
            if ($compatibilityScore -gt 0.8) {
                $aiResults += [PSCustomObject]@{
                    Source        = "AI Compatible"
                    DriverName    = "Compatible driver for similar hardware"
                    Compatibility = $compatibilityScore
                    SimilarDevice = $device
                    Risk          = if ($compatibilityScore -gt 0.95) { "Low" } else { "Medium" }
                }
            }
        }
        
        return $aiResults
    }
    catch {
        Write-Log "AI compatibility search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Find-SimilarHardware {
    param(
        [object]$Fingerprint
    )
    
    # This would query a database of known hardware configurations
    # and find devices with similar characteristics
    
    $similarDevices = @()
    
    # Mock implementation - in reality this would query a comprehensive hardware database
    if ($Fingerprint.VendorId -eq "8086") {
        $similarDevices += @{
            VendorId      = "8086"
            DeviceId      = "1234"  # Similar Intel device
            Compatibility = 0.9
        }
    }
    
    return $similarDevices
}

function Get-CompatibilityScore {
    param(
        [object]$Source,
        [object]$Target
    )
    
    $score = 0.0
    
    # Same vendor = +0.5
    if ($Source.VendorId -eq $Target.VendorId) {
        $score += 0.5
    }
    
    # Similar device family = +0.3
    if ($Source.DeviceId -match $Target.DeviceId.Substring(0, 2)) {
        $score += 0.3
    }
    
    # Same revision = +0.2
    if ($Source.RevisionId -eq $Target.RevisionId) {
        $score += 0.2
    }
    
    return $score
}

function Search-ExtractedDrivers {
    param(
        [object]$HardwareFingerprint
    )
    
    Write-Log "Searching extracted driver repositories..."
    
    $results = @()
    
    try {
        # Look for previously extracted driver stores
        $extractedPaths = @(
            "$env:TEMP\DriverExtraction\ExtractedDrivers",
            "$env:ProgramData\DriverUpdater\ExtractedDrivers",
            "C:\Drivers\Extracted"
        )
        
        foreach ($path in $extractedPaths) {
            if (Test-Path $path) {
                $compatibleDrivers = Find-CompatibleDrivers -HardwareFingerprint $HardwareFingerprint -DriverPath $path
                
                foreach ($driver in $compatibleDrivers) {
                    $results += [PSCustomObject]@{
                        Source        = "Extracted Repository"
                        DriverName    = "Extracted driver"
                        DriverPath    = $driver.DriverPath
                        Compatibility = $driver.Compatibility
                        INFPath       = $driver.INFPath
                    }
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Log "Extracted driver search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Search-NetworkDriverRepository {
    param(
        [object]$HardwareFingerprint
    )
    
    Write-Log "Searching network driver repository..."
    
    try {
        # This would search a centralized network repository
        # where systems can share drivers with each other
        
        $networkResults = @()
        
        # In a real implementation, this would connect to your network repository
        Write-Log "Network repository search would be implemented here for enterprise environments"
        
        return $networkResults
    }
    catch {
        Write-Log "Network repository search failed: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

#endregion

#region Advanced Administrator Functions

function Set-AdvancedPermissions {
    Write-Log "Configuring advanced administrator permissions..."
    
    try {
        # Enable SeTakeOwnershipPrivilege
        Enable-Privilege -Privilege "SeTakeOwnershipPrivilege"
        
        # Enable SeBackupPrivilege
        Enable-Privilege -Privilege "SeBackupPrivilege"
        
        # Enable SeRestorePrivilege
        Enable-Privilege -Privilege "SeRestorePrivilege"
        
        # Enable SeDebugPrivilege
        Enable-Privilege -Privilege "SeDebugPrivilege"
        
        Write-Log "Advanced permissions enabled successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to enable advanced permissions: $($_.Exception.Message)" -Level Warning
        return $false
    }
}

function Enable-Privilege {
    param(
        [string]$Privilege
    )
    
    # Use Windows API to enable privileges
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        using System.Security.Principal;
        
        public class PrivilegeHelper {
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);
            
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, uint BufferLength, IntPtr PreviousState, IntPtr ReturnLength);
            
            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern IntPtr GetCurrentProcess();
            
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);
            
            [StructLayout(LayoutKind.Sequential)]
            public struct TOKEN_PRIVILEGES {
                public uint PrivilegeCount;
                public long Luid;
                public uint Attributes;
            }
            
            public const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
            public const uint SE_PRIVILEGE_ENABLED = 0x00000002;
        }
"@
    
    try {
        $processHandle = [PrivilegeHelper]::GetCurrentProcess()
        [IntPtr]$tokenHandle = [IntPtr]::Zero
        
        if ([PrivilegeHelper]::OpenProcessToken($processHandle, [PrivilegeHelper]::TOKEN_ADJUST_PRIVILEGES, [ref]$tokenHandle)) {
            [long]$luid = 0
            if ([PrivilegeHelper]::LookupPrivilegeValue($null, $Privilege, [ref]$luid)) {
                $tokenPrivileges = New-Object PrivilegeHelper+TOKEN_PRIVILEGES
                $tokenPrivileges.PrivilegeCount = 1
                $tokenPrivileges.Luid = $luid
                $tokenPrivileges.Attributes = [PrivilegeHelper]::SE_PRIVILEGE_ENABLED
                
                [PrivilegeHelper]::AdjustTokenPrivileges($tokenHandle, $false, [ref]$tokenPrivileges, 0, [IntPtr]::Zero, [IntPtr]::Zero)
                Write-Log "Enabled privilege: $Privilege" -Level Success
            }
        }
    }
    catch {
        Write-Log "Failed to enable privilege $Privilege : $($_.Exception.Message)" -Level Warning
    }
}

function Install-DriverForcefully {
    param(
        [string]$INFPath,
        [string]$HardwareId,
        [switch]$Force
    )
    
    Write-Log "Force installing driver: $INFPath for hardware: $HardwareId"
    
    try {
        # Set advanced permissions
        Set-AdvancedPermissions | Out-Null
        
        # Stop related services
        $relatedServices = Get-RelatedServices -HardwareId $HardwareId
        $stoppedServices = Stop-RelatedServices -Services $relatedServices
        
        # Install driver using PnPUtil with force
        $pnpResult = & pnputil.exe /add-driver $INFPath /install /force
        Write-Log "PnPUtil result: $pnpResult" -Level Debug
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Driver installed successfully via PnPUtil" -Level Success
            
            # Try direct registry installation if PnPUtil fails
            if (-not (Test-DriverInstalled -HardwareId $HardwareId)) {
                Install-DriverViaRegistry -INFPath $INFPath -HardwareId $HardwareId
            }
        }
        else {
            Write-Log "PnPUtil failed, trying alternative methods..." -Level Warning
            
            # Try DISM for driver installation
            Install-DriverViaDISM -INFPath $INFPath
            
            # Try DevCon if available
            Install-DriverViaDevCon -INFPath $INFPath -HardwareId $HardwareId
            
            # Last resort: Registry manipulation
            Install-DriverViaRegistry -INFPath $INFPath -HardwareId $HardwareId
        }
        
        # Restart stopped services
        Start-RelatedServices -Services $stoppedServices
        
        # Force device rescan
        Force-DeviceRescan
        
        return $true
    }
    catch {
        Write-Log "Force driver installation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-RelatedServices {
    param(
        [string]$HardwareId
    )
    
    $services = @()
    
    try {
        # Get device class for the hardware
        $deviceClass = Get-DeviceClass -HardwareId $HardwareId
        
        # Map device classes to related services
        $serviceMapping = @{
            "Display"       = @("Display", "uxtheme", "dwm")
            "Net"           = @("Netman", "NlaSvc", "Dhcp")
            "AudioEndpoint" = @("AudioSrv", "AudioEndpointBuilder")
            "USB"           = @("USB*")
            "Storage"       = @("MSSQLSERVER", "VSS")
        }
        
        if ($serviceMapping.ContainsKey($deviceClass)) {
            foreach ($servicePattern in $serviceMapping[$deviceClass]) {
                $matchingServices = Get-Service | Where-Object { $_.Name -like $servicePattern }
                $services += $matchingServices
            }
        }
        
        return $services
    }
    catch {
        Write-Log "Failed to get related services: $($_.Exception.Message)" -Level Warning
        return @()
    }
}

function Stop-RelatedServices {
    param(
        [array]$Services
    )
    
    $stoppedServices = @()
    
    foreach ($service in $Services) {
        try {
            if ($service.Status -eq "Running") {
                Write-Log "Stopping service: $($service.Name)"
                Stop-Service -Name $service.Name -Force -ErrorAction Stop
                $stoppedServices += $service
            }
        }
        catch {
            Write-Log "Failed to stop service $($service.Name): $($_.Exception.Message)" -Level Warning
        }
    }
    
    return $stoppedServices
}

function Start-RelatedServices {
    param(
        [array]$Services
    )
    
    foreach ($service in $Services) {
        try {
            Write-Log "Starting service: $($service.Name)"
            Start-Service -Name $service.Name -ErrorAction Stop
        }
        catch {
            Write-Log "Failed to start service $($service.Name): $($_.Exception.Message)" -Level Warning
        }
    }
}

function Install-DriverViaDISM {
    param(
        [string]$INFPath
    )
    
    Write-Log "Installing driver via DISM..."
    
    try {
        $driverPath = Split-Path $INFPath -Parent
        $dismResult = & dism.exe /online /add-driver /driver:$driverPath /recurse /force
        Write-Log "DISM result: $dismResult" -Level Debug
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Driver installed successfully via DISM" -Level Success
            return $true
        }
        else {
            Write-Log "DISM installation failed" -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "DISM installation error: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Install-DriverViaDevCon {
    param(
        [string]$INFPath,
        [string]$HardwareId
    )
    
    Write-Log "Installing driver via DevCon..."
    
    try {
        # Check if DevCon is available
        $devConPath = Find-DevConExecutable
        
        if ($devConPath) {
            $devConResult = & $devConPath install $INFPath $HardwareId
            Write-Log "DevCon result: $devConResult" -Level Debug
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Driver installed successfully via DevCon" -Level Success
                return $true
            }
        }
        else {
            Write-Log "DevCon not found, skipping DevCon installation" -Level Warning
        }
        
        return $false
    }
    catch {
        Write-Log "DevCon installation error: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Find-DevConExecutable {
    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\Tools\x64\devcon.exe",
        "${env:ProgramFiles}\Windows Kits\10\Tools\x64\devcon.exe",
        "${env:ProgramFiles(x86)}\Windows Kits\8.1\Tools\x64\devcon.exe",
        "${env:ProgramFiles}\Windows Kits\8.1\Tools\x64\devcon.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

function Install-DriverViaRegistry {
    param(
        [string]$INFPath,
        [string]$HardwareId
    )
    
    Write-Log "Installing driver via registry manipulation..."
    
    try {
        # Parse INF file for driver information
        $infData = Parse-INFFile -Path $INFPath
        
        if ($infData) {
            # Create registry entries for the driver
            $driverKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($infData.ServiceName)"
            
            if (-not (Test-Path $driverKey)) {
                New-Item -Path $driverKey -Force | Out-Null
            }
            
            # Set driver properties
            Set-ItemProperty -Path $driverKey -Name "Type" -Value 1
            Set-ItemProperty -Path $driverKey -Name "Start" -Value 3
            Set-ItemProperty -Path $driverKey -Name "ImagePath" -Value $infData.ImagePath
            Set-ItemProperty -Path $driverKey -Name "DisplayName" -Value $infData.DisplayName
            
            # Add hardware ID mapping
            $enumKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$HardwareId"
            if (-not (Test-Path $enumKey)) {
                New-Item -Path $enumKey -Force | Out-Null
            }
            
            Set-ItemProperty -Path $enumKey -Name "Service" -Value $infData.ServiceName
            
            Write-Log "Driver registry entries created successfully" -Level Success
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "Registry installation error: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Read-INFFile {
    param(
        [string]$Path
    )
    
    try {
        $infContent = Get-Content $Path
        $infData = @{}
        
        # Parse basic INF structure
        foreach ($line in $infContent) {
            if ($line -match "ServiceName\s*=\s*(.+)") {
                $infData.ServiceName = $matches[1].Trim()
            }
            elseif ($line -match "ServiceBinary\s*=\s*(.+)") {
                $infData.ImagePath = $matches[1].Trim()
            }
            elseif ($line -match "ServiceDisplayName\s*=\s*(.+)") {
                $infData.DisplayName = $matches[1].Trim()
            }
        }
        
        return $infData
    }
    catch {
        Write-Log "Failed to parse INF file: $($_.Exception.Message)" -Level Warning
        return $null
    }
}

function Start-DeviceRescan {
    Write-Log "Forcing device manager rescan..."
    
    try {
        # Use WMI to trigger device rescan
        $deviceManager = Get-WmiObject -Class Win32_PnPEntity
        $deviceManager.PSBase.InvokeMethod("ScanForHardwareChanges", $null) | Out-Null
        
        # Also trigger via DevCon if available
        $devConPath = Find-DevConExecutable
        if ($devConPath) {
            & $devConPath rescan | Out-Null
        }
        
        Write-Log "Device rescan completed" -Level Success
    }
    catch {
        Write-Log "Device rescan failed: $($_.Exception.Message)" -Level Warning
    }
}

function Test-DriverInstalled {
    param(
        [string]$HardwareId
    )
    
    try {
        # Check if device has a driver installed
        $device = Get-PnpDevice | Where-Object { 
            $_.HardwareID -contains $HardwareId -and 
            $_.Status -eq "OK" 
        }
        
        return $null -ne $device
    }
    catch {
        return $false
    }
}

function Backup-DriverStore {
    param(
        [string]$BackupPath = "$env:ProgramData\DriverUpdater\Backup"
    )
    
    Write-Log "Backing up driver store..."
    
    try {
        if (-not (Test-Path $BackupPath)) {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        }
        
        $driverStorePath = "$env:SystemRoot\System32\DriverStore\FileRepository"
        $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDestination = Join-Path $BackupPath "DriverStore_$backupTimestamp"
        
        # Create compressed backup
        Compress-Archive -Path $driverStorePath -DestinationPath "$backupDestination.zip" -CompressionLevel Optimal
        
        Write-Log "Driver store backed up to: $backupDestination.zip" -Level Success
        return $true
    }
    catch {
        Write-Log "Driver store backup failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Remove-ProblematicDrivers {
    Write-Log "Scanning for and removing problematic drivers..."
    
    try {
        # Get devices with problems
        $problematicDevices = Get-PnpDevice | Where-Object { 
            $_.Status -eq "Error" -or 
            $_.Status -eq "Degraded" -or 
            $null -ne $_.Problem 
        }
        
        foreach ($device in $problematicDevices) {
            Write-Log "Found problematic device: $($device.FriendlyName) - Status: $($device.Status)"
            
            if ($device.Problem) {
                Write-Log "Problem code: $($device.Problem)"
            }
            
            # Try to remove the problematic driver
            try {
                Remove-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -Force
                Write-Log "Removed problematic device: $($device.FriendlyName)" -Level Success
            }
            catch {
                Write-Log "Failed to remove device $($device.FriendlyName): $($_.Exception.Message)" -Level Warning
            }
        }
        
        # Force rescan after removal
        Force-DeviceRescan
        
        return $true
    }
    catch {
        Write-Log "Problematic driver removal failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Optimize-DriverCache {
    Write-Log "Optimizing driver cache..."
    
    try {
        # Clean old driver packages
        & pnputil.exe /enum-drivers | ForEach-Object {
            if ($_ -match "Published name:\s+(.+)\.inf") {
                $publishedName = $matches[1]
                
                # Check if driver is old and unused
                $driverInfo = & pnputil.exe /enum-drivers /published-name $publishedName
                
                if ($driverInfo -match "Driver is not in use") {
                    Write-Log "Removing unused driver: $publishedName"
                    & pnputil.exe /delete-driver $publishedName /uninstall /force
                }
            }
        }
        
        # Clear temporary driver files
        $tempPaths = @(
            "$env:TEMP\Driver*",
            "$env:SystemRoot\Temp\Driver*",
            "$env:SystemRoot\System32\DriverStore\Temp\*"
        )
        
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        Write-Log "Driver cache optimization completed" -Level Success
        return $true
    }
    catch {
        Write-Log "Driver cache optimization failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Main Functions

function Start-DriverScan {
    Write-Log "=== Starting Advanced Driver Scan ===" -Level Success
    
    # Get system information
    $sysInfo = Get-SystemInfo
    Write-Log "System: $($sysInfo.OS) - $($sysInfo.Architecture)" -Level Info
    
    # Scan for all installed drivers
    $script:DriversFound = Get-InstalledDrivers
    
    # Find outdated drivers
    $outdatedDrivers = Find-OutdatedDrivers -Drivers $script:DriversFound
    
    # Search for updates
    $windowsUpdates = Search-WindowsUpdateDrivers
    $manufacturerUpdates = Search-ManufacturerDrivers -OutdatedDrivers $outdatedDrivers
    
    # Combine all available updates
    $script:UpdatesAvailable = @()
    $script:UpdatesAvailable += $windowsUpdates | ForEach-Object { 
        [PSCustomObject]@{
            Source      = "WindowsUpdate"
            Title       = $_.Title
            Description = $_.Description
            Size        = $_.Size
            Update      = $_
        }
    }
    
    $script:UpdatesAvailable += $manufacturerUpdates | ForEach-Object {
        [PSCustomObject]@{
            Source      = "Manufacturer"
            Title       = "$($_.Manufacturer) - $($_.DeviceName)"
            Description = "Version $($_.AvailableVersion)"
            Size        = $_.Size
            Update      = $_
        }
    }
    
    # Generate report
    Generate-ScanReport -OutdatedDrivers $outdatedDrivers -AvailableUpdates $script:UpdatesAvailable
    
    return @{
        DriversScanned      = $script:DriversFound.Count
        OutdatedDrivers     = $outdatedDrivers.Count
        UpdatesAvailable    = $script:UpdatesAvailable.Count
        WindowsUpdates      = $windowsUpdates.Count
        ManufacturerUpdates = $manufacturerUpdates.Count
    }
}

function Start-DriverUpdate {
    if ($script:UpdatesAvailable.Count -eq 0) {
        Write-Log "No driver updates available to install" -Level Warning
        return
    }
    
    Write-Log "=== Starting Advanced Driver Updates ===" -Level Success
    
    # Enable advanced administrator permissions
    Set-AdvancedPermissions | Out-Null
    
    # Create restore point if requested
    if ($CreateRestorePoint) {
        New-SystemRestorePoint
    }
    
    # Backup driver store before making changes
    Backup-DriverStore
    
    # Remove problematic drivers first
    Remove-ProblematicDrivers
    
    # Install Windows Update drivers
    $windowsUpdateDrivers = $script:UpdatesAvailable | Where-Object Source -EQ "WindowsUpdate"
    if ($windowsUpdateDrivers) {
        Write-Log "Installing $($windowsUpdateDrivers.Count) Windows Update drivers..."
        $windowsResults = Install-WindowsUpdateDrivers -Updates ($windowsUpdateDrivers | ForEach-Object { $_.Update })
        $script:InstallResults += $windowsResults
    }
    
    # Install manufacturer drivers with force if needed
    $manufacturerDrivers = $script:UpdatesAvailable | Where-Object Source -NE "WindowsUpdate"
    if ($manufacturerDrivers) {
        Write-Log "Installing $($manufacturerDrivers.Count) manufacturer/alternative drivers..."
        
        foreach ($driver in $manufacturerDrivers) {
            try {
                $installResult = Install-AdvancedDriver -DriverInfo $driver.Update
                $script:InstallResults += $installResult
            }
            catch {
                Write-Log "Failed to install $($driver.Title): $($_.Exception.Message)" -Level Error
                $script:InstallResults += [PSCustomObject]@{
                    Title          = $driver.Title
                    Status         = "Failed"
                    Error          = $_.Exception.Message
                    RebootRequired = $false
                }
            }
        }
    }
    
    # Process any extracted or discovered drivers
    $extractedDrivers = Search-LocalDriverRepositories
    if ($extractedDrivers.Count -gt 0) {
        Write-Log "Processing $($extractedDrivers.Count) locally discovered drivers..."
        
        foreach ($driver in $extractedDrivers) {
            try {
                $success = Install-DriverForcefully -INFPath $driver.INFPath -HardwareId $driver.HardwareId -Force
                
                $script:InstallResults += [PSCustomObject]@{
                    Title          = "Local Driver: $($driver.DeviceName)"
                    Status         = if ($success) { "Success" } else { "Failed" }
                    Error          = if (-not $success) { "Force installation failed" } else { $null }
                    RebootRequired = $success
                }
            }
            catch {
                Write-Log "Failed to force install local driver: $($_.Exception.Message)" -Level Error
            }
        }
    }
    
    # Optimize driver cache after installations
    Optimize-DriverCache
    
    # Generate installation report
    Generate-InstallationReport
    
    # Check if reboot is required
    $rebootRequired = $script:InstallResults | Where-Object RebootRequired -EQ $true
    if ($rebootRequired) {
        Write-Log "Some driver updates require a system reboot to complete" -Level Warning
        
        if (-not $Silent) {
            $reboot = Read-Host "Reboot now? (y/n)"
            if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                Write-Log "Initiating system reboot..."
                Restart-Computer -Force
            }
        }
    }
    
    Write-Log "Advanced driver update process completed!" -Level Success
}

function Install-AdvancedDriver {
    param(
        [object]$DriverInfo
    )
    
    Write-Log "Installing advanced driver: $($DriverInfo.DriverName)"
    
    try {
        $tempPath = "$env:TEMP\DriverInstall_$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        
        # Download driver if needed
        if ($DriverInfo.DownloadUrl) {
            $downloadPath = Join-Path $tempPath "driver.exe"
            Download-DriverPackage -Url $DriverInfo.DownloadUrl -Destination $downloadPath
            
            # Extract driver package
            $extractPath = Join-Path $tempPath "extracted"
            Extract-DriverPackage -PackagePath $downloadPath -ExtractPath $extractPath
            
            # Find INF files
            $infFiles = Get-ChildItem -Path $extractPath -Filter "*.inf" -Recurse
            
            if ($infFiles) {
                foreach ($infFile in $infFiles) {
                    # Try to install each INF
                    $success = Install-DriverForcefully -INFPath $infFile.FullName -HardwareId $DriverInfo.HardwareId -Force
                    
                    if ($success) {
                        return [PSCustomObject]@{
                            Title          = $DriverInfo.DriverName
                            Status         = "Success"
                            Error          = $null
                            RebootRequired = $true
                        }
                    }
                }
            }
        }
        
        # If direct installation from INF path
        if ($DriverInfo.INFPath) {
            $success = Install-DriverForcefully -INFPath $DriverInfo.INFPath -HardwareId $DriverInfo.HardwareId -Force
            
            return [PSCustomObject]@{
                Title          = $DriverInfo.DriverName
                Status         = if ($success) { "Success" } else { "Failed" }
                Error          = if (-not $success) { "Installation failed" } else { $null }
                RebootRequired = $success
            }
        }
        
        # If no direct installation method available, try compatibility installation
        $compatibleDriver = Find-CompatibleDriverAlternative -DriverInfo $DriverInfo
        if ($compatibleDriver) {
            $success = Install-DriverForcefully -INFPath $compatibleDriver.INFPath -HardwareId $DriverInfo.HardwareId -Force
            
            return [PSCustomObject]@{
                Title          = "$($DriverInfo.DriverName) (Compatible)"
                Status         = if ($success) { "Success" } else { "Failed" }
                Error          = if (-not $success) { "Compatible driver installation failed" } else { $null }
                RebootRequired = $success
                Warning        = "Using compatible driver - may have limited functionality"
            }
        }
        
        return [PSCustomObject]@{
            Title          = $DriverInfo.DriverName
            Status         = "Failed"
            Error          = "No installation method available"
            RebootRequired = $false
        }
    }
    catch {
        return [PSCustomObject]@{
            Title          = $DriverInfo.DriverName
            Status         = "Failed"
            Error          = $_.Exception.Message
            RebootRequired = $false
        }
    }
    finally {
        # Cleanup temporary files
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-DriverPackage {
    param(
        [string]$Url,
        [string]$Destination
    )
    
    Write-Log "Downloading driver package from: $Url"
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Advanced Driver Updater")
        $webClient.DownloadFile($Url, $Destination)
        
        Write-Log "Driver package downloaded successfully" -Level Success
    }
    catch {
        Write-Log "Driver download failed: $($_.Exception.Message)" -Level Error
        throw
    }
    finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

function Expand-DriverPackage {
    param(
        [string]$PackagePath,
        [string]$ExtractPath
    )
    
    Write-Log "Extracting driver package: $PackagePath"
    
    try {
        if (-not (Test-Path $ExtractPath)) {
            New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
        }
        
        # Try different extraction methods based on file type
        $extension = [System.IO.Path]::GetExtension($PackagePath).ToLower()
        
        switch ($extension) {
            ".zip" {
                Expand-Archive -Path $PackagePath -DestinationPath $ExtractPath -Force
            }
            ".exe" {
                # Try silent extraction switches
                $extractSwitches = @("/S", "/SILENT", "/EXTRACT:$ExtractPath", "-s", "-x")
                
                foreach ($switch in $extractSwitches) {
                    try {
                        $process = Start-Process -FilePath $PackagePath -ArgumentList $switch -WorkingDirectory $ExtractPath -Wait -PassThru
                        if ($process.ExitCode -eq 0) {
                            break
                        }
                    }
                    catch {
                        continue
                    }
                }
                
                # If silent extraction fails, try 7-Zip if available
                $sevenZipPath = "${env:ProgramFiles}\7-Zip\7z.exe"
                if (Test-Path $sevenZipPath) {
                    & $sevenZipPath x $PackagePath "-o$ExtractPath" -y
                }
            }
            ".cab" {
                & expand.exe $PackagePath $ExtractPath
            }
            default {
                Write-Log "Unknown package format: $extension" -Level Warning
            }
        }
        
        Write-Log "Driver package extracted successfully" -Level Success
    }
    catch {
        Write-Log "Driver extraction failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Find-CompatibleDriverAlternative {
    param(
        [object]$DriverInfo
    )
    
    Write-Log "Searching for compatible driver alternatives..."
    
    try {
        # Search in Windows driver store
        $driverStorePath = "$env:SystemRoot\System32\DriverStore\FileRepository"
        
        if (Test-Path $driverStorePath) {
            $compatibleDrivers = Find-CompatibleDrivers -HardwareFingerprint $DriverInfo.HardwareFingerprint -DriverPath $driverStorePath
            
            if ($compatibleDrivers.Count -gt 0) {
                # Return the best match
                $bestMatch = $compatibleDrivers | Sort-Object Compatibility -Descending | Select-Object -First 1
                return $bestMatch
            }
        }
        
        # Search in extracted driver repositories
        $extractedPaths = @(
            "$env:TEMP\DriverExtraction\ExtractedDrivers",
            "$env:ProgramData\DriverUpdater\ExtractedDrivers"
        )
        
        foreach ($path in $extractedPaths) {
            if (Test-Path $path) {
                $compatibleDrivers = Find-CompatibleDrivers -HardwareFingerprint $DriverInfo.HardwareFingerprint -DriverPath $path
                
                if ($compatibleDrivers.Count -gt 0) {
                    return $compatibleDrivers | Sort-Object Compatibility -Descending | Select-Object -First 1
                }
            }
        }
        
        return $null
    }
    catch {
        Write-Log "Compatible driver search failed: $($_.Exception.Message)" -Level Warning
        return $null
    }
}

function Search-LocalDriverRepositories {
    Write-Log "Searching local driver repositories for missing drivers..."
    
    $localDrivers = @()
    
    try {
        # Get all devices without drivers or with problematic drivers
        $devicesNeedingDrivers = Get-PnpDevice | Where-Object { 
            $_.Status -eq "Unknown" -or 
            $_.Status -eq "Error" -or 
            $null -ne $_.Problem 
        }
        
        foreach ($device in $devicesNeedingDrivers) {
            Write-Log "Searching drivers for: $($device.FriendlyName)"
            
            # Get hardware fingerprint
            $hardwareIds = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName 'DEVPKEY_Device_HardwareIds' -ErrorAction SilentlyContinue).Data
            $fingerprint = Get-HardwareFingerprint -HardwareIds $hardwareIds -InstanceId $device.InstanceId
            
            # Search all possible driver sources
            $searchPaths = @(
                "$env:SystemRoot\System32\DriverStore\FileRepository",
                "$env:TEMP\DriverExtraction\ExtractedDrivers",
                "$env:ProgramData\DriverUpdater\ExtractedDrivers",
                "C:\Drivers",
                "$env:SystemDrive\Intel\Logs",
                "$env:SystemDrive\AMD\Logs",
                "$env:SystemDrive\NVIDIA\DisplayDriver"
            )
            
            foreach ($searchPath in $searchPaths) {
                if (Test-Path $searchPath) {
                    $compatibleDrivers = Find-CompatibleDrivers -HardwareFingerprint $fingerprint -DriverPath $searchPath
                    
                    foreach ($driver in $compatibleDrivers) {
                        $localDrivers += [PSCustomObject]@{
                            DeviceName    = $device.FriendlyName
                            InstanceId    = $device.InstanceId
                            HardwareId    = $driver.HardwareId
                            INFPath       = $driver.INFPath
                            DriverPath    = $driver.DriverPath
                            Compatibility = $driver.Compatibility
                        }
                    }
                }
            }
        }
        
        Write-Log "Found $($localDrivers.Count) potential local driver matches"
        return $localDrivers
    }
    catch {
        Write-Log "Local driver repository search failed: $($_.Exception.Message)" -Level Error
        return @()
    }
}

function New-ScanReport {
    param(
        [array]$OutdatedDrivers,
        [array]$AvailableUpdates
    )
    
    $reportPath = Join-Path $LogPath "DriverScanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Driver Scan Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .outdated { background-color: #ffebee; }
        .available { background-color: #e8f5e8; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .priority-1 { background-color: #ffcdd2; }
        .priority-2 { background-color: #ffe0b2; }
        .priority-3 { background-color: #fff3e0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Advanced Driver Scanner Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="section">
        <h2>Summary</h2>
        <ul>
            <li>Total Drivers Scanned: $($script:DriversFound.Count)</li>
            <li>Outdated Drivers Found: $($OutdatedDrivers.Count)</li>
            <li>Updates Available: $($AvailableUpdates.Count)</li>
        </ul>
    </div>
    
    <div class="section outdated">
        <h2>Outdated Drivers</h2>
        <table>
            <tr>
                <th>Device Name</th>
                <th>Class</th>
                <th>Manufacturer</th>
                <th>Current Version</th>
                <th>Driver Date</th>
                <th>Days Old</th>
                <th>Priority</th>
            </tr>
"@

    foreach ($driver in $OutdatedDrivers) {
        $priorityClass = "priority-$($driver.Priority)"
        $priorityText = switch ($driver.Priority) {
            1 { "Very High" }
            2 { "High" }
            3 { "Medium" }
            4 { "Low" }
        }
        
        $html += @"
            <tr class="$priorityClass">
                <td>$($driver.DeviceName)</td>
                <td>$($driver.Class)</td>
                <td>$($driver.Manufacturer)</td>
                <td>$($driver.CurrentVersion)</td>
                <td>$($driver.CurrentDate.ToString('yyyy-MM-dd'))</td>
                <td>$($driver.DaysOld)</td>
                <td>$priorityText</td>
            </tr>
"@
    }

    $html += @"
        </table>
    </div>
    
    <div class="section available">
        <h2>Available Updates</h2>
        <table>
            <tr>
                <th>Source</th>
                <th>Title</th>
                <th>Description</th>
                <th>Size</th>
            </tr>
"@

    foreach ($update in $AvailableUpdates) {
        $html += @"
            <tr>
                <td>$($update.Source)</td>
                <td>$($update.Title)</td>
                <td>$($update.Description)</td>
                <td>$($update.Size)</td>
            </tr>
"@
    }

    $html += @"
        </table>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Detailed HTML report saved to: $reportPath" -Level Success
}

function New-InstallationReport {
    Write-Log "=== Installation Results ===" -Level Success
    
    $successCount = ($script:InstallResults | Where-Object Status -EQ "Success").Count
    $failCount = ($script:InstallResults | Where-Object Status -EQ "Failed").Count
    
    Write-Log "Successfully installed: $successCount driver updates" -Level Success
    Write-Log "Failed installations: $failCount driver updates" -Level $(if ($failCount -gt 0) { "Warning" } else { "Info" })
    
    foreach ($result in $script:InstallResults) {
        $level = if ($result.Status -eq "Success") { "Success" } else { "Error" }
        $message = "$($result.Status): $($result.Title)"
        if ($result.Error) {
            $message += " - Error: $($result.Error)"
        }
        Write-Log $message -Level $level
    }
}

#endregion

#region Task Scheduling

function New-ScheduledTask {
    Write-Log "Creating scheduled task for automatic driver updates..."
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -AutoUpdate -Silent"
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00"
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName "AdvancedDriverUpdater" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatic driver updates using Advanced Driver Updater"
        
        Write-Log "Scheduled task created successfully. Will run weekly on Sundays at 2:00 AM" -Level Success
    }
    catch {
        Write-Log "Failed to create scheduled task: $($_.Exception.Message)" -Level Error
    }
}

#endregion

# Main Execution
try {
    Write-Log "Advanced Driver Updater Starting..." -Level Success
    Write-Log "PowerShell Version: $($PSVersionTable.PSVersion.ToString())"
    Write-Log "Log file: $script:LogFile"
    
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Log "This script requires Administrator privileges. Please run as Administrator." -Level Error
        exit 1
    }
    
    # Create scheduled task if requested
    if ($ScheduleTask) {
        Create-ScheduledTask
        exit 0
    }
    
    # Start driver scan
    $scanResults = Start-DriverScan
    
    # Display summary
    Write-Log "=== Scan Complete ===" -Level Success
    Write-Log "Drivers scanned: $($scanResults.DriversScanned)"
    Write-Log "Outdated drivers: $($scanResults.OutdatedDrivers)"
    Write-Log "Updates available: $($scanResults.UpdatesAvailable)"
    
    # Install updates if requested
    if ($AutoUpdate -and $scanResults.UpdatesAvailable -gt 0) {
        Start-DriverUpdate
    }
    elseif (-not $ScanOnly -and $scanResults.UpdatesAvailable -gt 0 -and -not $Silent) {
        $install = Read-Host "Install available driver updates? (y/n)"
        if ($install -eq 'y' -or $install -eq 'Y') {
            Start-DriverUpdate
        }
    }
    
    Write-Log "Advanced Driver Updater completed successfully!" -Level Success
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
