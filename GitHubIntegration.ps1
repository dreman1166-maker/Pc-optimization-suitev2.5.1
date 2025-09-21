<#
.SYNOPSIS
    PC Optimization Suite - GitHub Integration & Auto-Update System

.DESCRIPTION
    This script provides GitHub integration for automatic version control,
    release management, and update distribution. It allows you to:
    - Push updates to GitHub
    - Create automatic releases
    - Manage version tags
    - Provide update endpoints for automatic client updates

.PARAMETER Action
    Action to perform: 'publish', 'create-release', 'setup-repo', 'update-clients'

.PARAMETER Version
    Version number for the release

.PARAMETER ReleaseNotes
    Path to release notes file or direct notes text

.PARAMETER Token
    GitHub personal access token (optional if already configured)

.PARAMETER Repository
    GitHub repository in format owner/repo

.EXAMPLE
    .\GitHubIntegration.ps1 -Action setup-repo
    .\GitHubIntegration.ps1 -Action publish -Version "2.0.2"
    .\GitHubIntegration.ps1 -Action create-release -Version "2.0.2" -ReleaseNotes "Bug fixes and improvements"

.AUTHOR
    PC Optimization Suite GitHub Integration v1.0
#>

param(
    [ValidateSet("setup-repo", "publish", "create-release", "update-clients", "status")]
    [string]$Action = "status",
    
    [string]$Version = "",
    
    [string]$ReleaseNotes = "",
    
    [string]$Token = "",
    
    [string]$Repository = "",
    
    [switch]$Force,
    
    [switch]$CreateAssets
)

# Configuration
$script:ConfigFile = Join-Path $PSScriptRoot "github-config.json"
$script:SourcePath = $PSScriptRoot
$script:DefaultBranch = "main"
$script:ReleaseBranch = "releases"

# Core files to include in releases
$script:CoreFiles = @(
    "PCOptimizationLauncher.ps1",
    "AdvancedDriverUpdater.ps1", 
    "SystemLogger.ps1",
    "PCOptimizationSuite.ps1",
    "DriverUpdaterManager.ps1",
    "DriverUpdaterConfig.ini",
    "BuildDistribution.ps1",
    "GitHubIntegration.ps1"
)

#region Utility Functions

function Write-GitLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        "Info"    = "White"
        "Warning" = "Yellow"
        "Error"   = "Red" 
        "Success" = "Green"
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-GitRepository {
    <#
    .SYNOPSIS
    Checks if current directory is a git repository
    #>
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        return $null -ne $gitDir
    }
    catch {
        return $false
    }
}

function Test-GitHubCLI {
    <#
    .SYNOPSIS
    Checks if GitHub CLI is installed and authenticated
    #>
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            $authStatus = gh auth status 2>$null
            return $authStatus -match "Logged in"
        }
        return $false
    }
    catch {
        return $false
    }
}

function Get-GitHubConfig {
    <#
    .SYNOPSIS
    Loads GitHub configuration from file
    #>
    try {
        if (Test-Path $script:ConfigFile) {
            $config = Get-Content $script:ConfigFile -Raw | ConvertFrom-Json
            return $config
        }
        else {
            return @{
                Repository      = ""
                Token           = ""
                UpdateServer    = ""
                LastRelease     = ""
                AutoUpdate      = $true
                ReleaseTemplate = "release-template.md"
            }
        }
    }
    catch {
        Write-GitLog "Error loading GitHub configuration: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Set-GitHubConfig {
    param([hashtable]$Config)
    
    try {
        $Config | ConvertTo-Json -Depth 3 | Set-Content $script:ConfigFile -Encoding UTF8
        Write-GitLog "GitHub configuration saved" -Level Success
        return $true
    }
    catch {
        Write-GitLog "Error saving GitHub configuration: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-CurrentVersion {
    <#
    .SYNOPSIS
    Extracts current version from launcher script
    #>
    try {
        $launcherPath = Join-Path $script:SourcePath "PCOptimizationLauncher.ps1"
        if (Test-Path $launcherPath) {
            $content = Get-Content $launcherPath -Raw
            if ($content -match '\$script:CurrentVersion\s*=\s*"([^"]+)"') {
                return $matches[1]
            }
        }
        return "1.0.0"
    }
    catch {
        Write-GitLog "Error getting current version: $($_.Exception.Message)" -Level Warning
        return "1.0.0"
    }
}

function Update-VersionInFiles {
    param([string]$NewVersion)
    
    try {
        $filesToUpdate = @(
            @{
                Path        = "PCOptimizationLauncher.ps1"
                Pattern     = '(\$script:CurrentVersion\s*=\s*")([^"]+)(")'
                Replacement = "`${1}$NewVersion`${3}"
            },
            @{
                Path        = "BuildDistribution.ps1" 
                Pattern     = '(\$script:Version\s*=\s*")([^"]+)(")'
                Replacement = "`${1}$NewVersion`${3}"
            }
        )
        
        foreach ($file in $filesToUpdate) {
            $filePath = Join-Path $script:SourcePath $file.Path
            if (Test-Path $filePath) {
                $content = Get-Content $filePath -Raw
                $updatedContent = $content -replace $file.Pattern, $file.Replacement
                Set-Content $filePath $updatedContent -Encoding UTF8
                Write-GitLog "Updated version in $($file.Path)" -Level Success
            }
        }
        
        return $true
    }
    catch {
        Write-GitLog "Error updating version in files: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Git Operations

function Initialize-GitRepository {
    <#
    .SYNOPSIS
    Initializes git repository if not already present
    #>
    try {
        if (-not (Test-GitRepository)) {
            Write-GitLog "Initializing Git repository..." -Level Info
            git init
            
            # Create .gitignore
            $gitignoreContent = @"
# Logs
Logs/*.log
Logs/*.json
*.log

# Temporary files
Temp/
*.tmp
*.temp

# User configuration
Config/user-settings.json
Config/local-*.json

# Backups
Backups/
*.backup

# Build outputs
Distributions/
*.zip

# PowerShell specific
*.ps1xml

# Windows specific
Thumbs.db
desktop.ini
*.lnk

# IDE files
.vscode/settings.json
.vs/

# Sensitive data
*token*
*password*
*secret*
github-config.json
"@
            $gitignoreContent | Set-Content ".gitignore" -Encoding UTF8
            
            git add .gitignore
            git commit -m "Initial commit with .gitignore"
            
            Write-GitLog "Git repository initialized" -Level Success
        }
        else {
            Write-GitLog "Git repository already exists" -Level Info
        }
        
        return $true
    }
    catch {
        Write-GitLog "Error initializing Git repository: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Add-FilesToGit {
    <#
    .SYNOPSIS
    Adds specified files to git staging
    #>
    try {
        foreach ($file in $script:CoreFiles) {
            $filePath = Join-Path $script:SourcePath $file
            if (Test-Path $filePath) {
                git add $file
                Write-GitLog "Added $file to staging" -Level Info
            }
            else {
                Write-GitLog "File not found: $file" -Level Warning
            }
        }
        
        # Add additional important files
        $additionalFiles = @("README.md", ".gitignore", "github-config.json")
        foreach ($file in $additionalFiles) {
            if (Test-Path $file) {
                git add $file
                Write-GitLog "Added $file to staging" -Level Info
            }
        }
        
        return $true
    }
    catch {
        Write-GitLog "Error adding files to Git: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function New-GitCommit {
    param(
        [string]$Message,
        [string]$Version = ""
    )
    
    try {
        if ($Version) {
            $commitMessage = "Release v$Version - $Message"
        }
        else {
            $commitMessage = $Message
        }
        
        git commit -m $commitMessage
        Write-GitLog "Created commit: $commitMessage" -Level Success
        return $true
    }
    catch {
        Write-GitLog "Error creating Git commit: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function New-GitTag {
    param(
        [string]$Version,
        [string]$Message = ""
    )
    
    try {
        $tagName = "v$Version"
        
        if ($Message) {
            git tag -a $tagName -m $Message
        }
        else {
            git tag -a $tagName -m "Release version $Version"
        }
        
        Write-GitLog "Created tag: $tagName" -Level Success
        return $tagName
    }
    catch {
        Write-GitLog "Error creating Git tag: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Push-ToGitHub {
    param([string]$Branch = $script:DefaultBranch)
    
    try {
        Write-GitLog "Pushing to GitHub branch: $Branch" -Level Info
        
        git push origin $Branch
        git push origin --tags
        
        Write-GitLog "Successfully pushed to GitHub" -Level Success
        return $true
    }
    catch {
        Write-GitLog "Error pushing to GitHub: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region GitHub Release Management

function New-GitHubRelease {
    param(
        [string]$Version,
        [string]$ReleaseNotes,
        [string]$Repository,
        [bool]$PreRelease = $false
    )
    
    try {
        $tagName = "v$Version"
        $releaseName = "PC Optimization Suite v$Version"
        
        Write-GitLog "Creating GitHub release: $releaseName" -Level Info
        
        # Use GitHub CLI if available
        if (Test-GitHubCLI) {
            $ghArgs = @(
                "release", "create", $tagName,
                "--title", $releaseName,
                "--notes", $ReleaseNotes
            )
            
            if ($PreRelease) {
                $ghArgs += "--prerelease"
            }
            
            & gh @ghArgs
            Write-GitLog "GitHub release created using CLI" -Level Success
        }
        else {
            # Fallback to API call
            $config = Get-GitHubConfig
            if (-not $config.Token) {
                Write-GitLog "GitHub token required for API access" -Level Error
                return $false
            }
            
            $releaseData = @{
                tag_name         = $tagName
                target_commitish = $script:DefaultBranch
                name             = $releaseName
                body             = $ReleaseNotes
                draft            = $false
                prerelease       = $PreRelease
            }
            
            $headers = @{
                "Authorization" = "token $($config.Token)"
                "Accept"        = "application/vnd.github.v3+json"
                "User-Agent"    = "PC-Optimization-Suite"
            }
            
            $apiUrl = "https://api.github.com/repos/$Repository/releases"
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body ($releaseData | ConvertTo-Json) -ContentType "application/json"
            
            Write-GitLog "GitHub release created via API" -Level Success
        }
        
        return $true
    }
    catch {
        Write-GitLog "Error creating GitHub release: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Add-ReleaseAssets {
    param(
        [string]$Version,
        [string]$Repository
    )
    
    try {
        Write-GitLog "Creating distribution packages for release..." -Level Info
        
        # Run build script to create distribution packages
        $buildScript = Join-Path $script:SourcePath "BuildDistribution.ps1"
        if (Test-Path $buildScript) {
            $buildOutput = Join-Path (Split-Path $script:SourcePath -Parent) "Distributions"
            & $buildScript -BuildType "All" -OutputPath $buildOutput
            
            # Find the latest build folder
            $latestBuild = Get-ChildItem $buildOutput -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
            
            if ($latestBuild) {
                $assetFiles = @()
                
                # Find ZIP files in the build directory
                Get-ChildItem $latestBuild.FullName -Filter "*.zip" | ForEach-Object {
                    $assetFiles += $_.FullName
                }
                
                # Upload assets using GitHub CLI
                if (Test-GitHubCLI -and $assetFiles.Count -gt 0) {
                    foreach ($asset in $assetFiles) {
                        Write-GitLog "Uploading asset: $(Split-Path $asset -Leaf)" -Level Info
                        gh release upload "v$Version" $asset --repo $Repository
                    }
                    Write-GitLog "Release assets uploaded successfully" -Level Success
                }
                else {
                    Write-GitLog "No ZIP files found or GitHub CLI not available" -Level Warning
                }
            }
        }
        else {
            Write-GitLog "Build script not found: $buildScript" -Level Warning
        }
        
        return $true
    }
    catch {
        Write-GitLog "Error adding release assets: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-ReleaseNotes {
    param([string]$Version)
    
    # Try to get release notes from file
    $notesFile = Join-Path $script:SourcePath "RELEASE_NOTES.md"
    if (Test-Path $notesFile) {
        return Get-Content $notesFile -Raw
    }
    
    # Generate default release notes
    $defaultNotes = @"
# PC Optimization Suite v$Version

## What's New
- Enhanced system optimization algorithms
- Improved driver detection and updating
- Better error handling and logging
- Performance improvements across all modules
- Bug fixes and stability improvements

## Features
- 🚀 Automatic driver updates with fallback mechanisms
- 🧹 Comprehensive system cleaning and optimization
- 📊 Real-time performance monitoring
- 🎮 Gaming mode optimization
- 🔄 Automatic update system
- 📝 Detailed logging and reporting
- 💾 Backup and recovery capabilities

## System Requirements
- Windows 10/11 (64-bit recommended)
- PowerShell 5.1 or higher
- Administrator privileges (recommended)
- 50MB free disk space
- Internet connection (for updates)

## Installation
1. Download the installer package
2. Run Install.bat or Install.ps1
3. Follow the setup wizard
4. Launch from desktop shortcut or Start Menu

## Changes in v$Version
- Performance optimizations
- Enhanced compatibility
- Improved user interface
- Bug fixes

For technical support and documentation, visit the GitHub repository.
"@
    
    return $defaultNotes
}

#endregion

#region Update Server Management

function Update-ReleaseAPI {
    param(
        [string]$Version,
        [string]$Repository
    )
    
    try {
        Write-GitLog "Updating release API information..." -Level Info
        
        # Create version API response
        $apiResponse = @{
            latest_version        = $Version
            release_date          = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            download_url          = "https://github.com/$Repository/releases/download/v$Version/"
            release_notes_url     = "https://github.com/$Repository/releases/tag/v$Version"
            update_notes          = @(
                "Enhanced performance optimization",
                "Improved driver detection and compatibility", 
                "Better system stability and error handling",
                "New features and user interface improvements",
                "Bug fixes and security updates"
            )
            minimum_version       = "2.0.0"
            auto_update_available = $true
            compatibility         = @{
                windows_versions    = @("Windows 10", "Windows 11")
                powershell_versions = @("5.1", "7.0+")
            }
            packages              = @{
                installer = "PCOptimizationSuite_Installer.zip"
                portable  = "PCOptimizationSuite_Portable.zip" 
                update    = "PCOptimizationSuite_Update.zip"
            }
        }
        
        # Save API response
        $apiFile = Join-Path $script:SourcePath "version-api.json"
        $apiResponse | ConvertTo-Json -Depth 4 | Set-Content $apiFile -Encoding UTF8
        
        # Commit API update
        git add $apiFile
        git commit -m "Update version API for v$Version"
        
        Write-GitLog "Release API updated" -Level Success
        return $true
    }
    catch {
        Write-GitLog "Error updating release API: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-UpdateEndpoint {
    param([string]$Repository)
    
    try {
        $apiUrl = "https://raw.githubusercontent.com/$Repository/$($script:DefaultBranch)/version-api.json"
        Write-GitLog "Testing update endpoint: $apiUrl" -Level Info
        
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get
        
        if ($response.latest_version) {
            Write-GitLog "Update endpoint is working. Latest version: $($response.latest_version)" -Level Success
            return $true
        }
        else {
            Write-GitLog "Update endpoint returned invalid response" -Level Error
            return $false
        }
    }
    catch {
        Write-GitLog "Error testing update endpoint: $($_.Exception.Message)" -Level Error
        return $false
    }
}

#endregion

#region Action Handlers

function Invoke-SetupRepository {
    Write-GitLog "Setting up GitHub repository..." -Level Info
    
    # Initialize git if needed
    if (-not (Initialize-GitRepository)) {
        return $false
    }
    
    # Get repository information
    $config = Get-GitHubConfig
    
    if (-not $config.Repository) {
        Write-Host "GitHub Repository Setup" -ForegroundColor Cyan
        Write-Host "========================" -ForegroundColor Cyan
        Write-Host ""
        
        $repoName = Read-Host "Enter GitHub repository (owner/repo)"
        if (-not $repoName -or $repoName -notmatch "^[^/]+/[^/]+$") {
            Write-GitLog "Invalid repository format. Use: owner/repo" -Level Error
            return $false
        }
        
        $config.Repository = $repoName
    }
    
    # Check GitHub CLI authentication
    if (-not (Test-GitHubCLI)) {
        Write-Host ""
        Write-Host "GitHub CLI Setup Required" -ForegroundColor Yellow
        Write-Host "=========================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please install GitHub CLI and authenticate:" -ForegroundColor White
        Write-Host "1. Install GitHub CLI: https://cli.github.com/" -ForegroundColor Gray
        Write-Host "2. Run: gh auth login" -ForegroundColor Gray
        Write-Host "3. Follow the authentication process" -ForegroundColor Gray
        Write-Host ""
        
        $continue = Read-Host "Continue with manual token setup? (Y/N) [N]"
        if ($continue -match '^[Yy]') {
            $token = Read-Host "Enter GitHub Personal Access Token" -AsSecureString
            $config.Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
        }
        else {
            Write-GitLog "GitHub CLI setup required. Please run 'gh auth login' first." -Level Warning
            return $false
        }
    }
    
    # Set update server URL
    $config.UpdateServer = "https://raw.githubusercontent.com/$($config.Repository)/$($script:DefaultBranch)"
    $config.AutoUpdate = $true
    
    # Save configuration
    if (-not (Set-GitHubConfig -Config $config)) {
        return $false
    }
    
    # Add initial files
    if (-not (Add-FilesToGit)) {
        return $false
    }
    
    # Create initial commit
    if (-not (New-GitCommit -Message "Initial setup of PC Optimization Suite")) {
        return $false
    }
    
    # Set up remote if not already configured
    try {
        $remoteUrl = git remote get-url origin 2>$null
        if (-not $remoteUrl) {
            $repoUrl = "https://github.com/$($config.Repository).git"
            git remote add origin $repoUrl
            Write-GitLog "Added remote origin: $repoUrl" -Level Success
        }
    }
    catch {
        Write-GitLog "Warning: Could not configure remote origin" -Level Warning
    }
    
    Write-GitLog "GitHub repository setup completed" -Level Success
    return $true
}

function Invoke-PublishVersion {
    param([string]$VersionNumber)
    
    if (-not $VersionNumber) {
        $currentVersion = Get-CurrentVersion
        Write-Host "Current version: $currentVersion" -ForegroundColor Yellow
        $VersionNumber = Read-Host "Enter new version number"
    }
    
    if (-not $VersionNumber) {
        Write-GitLog "Version number required" -Level Error
        return $false
    }
    
    Write-GitLog "Publishing version $VersionNumber..." -Level Info
    
    # Update version in files
    if (-not (Update-VersionInFiles -NewVersion $VersionNumber)) {
        return $false
    }
    
    # Add files to git
    if (-not (Add-FilesToGit)) {
        return $false
    }
    
    # Create commit
    if (-not (New-GitCommit -Message "Version bump and improvements" -Version $VersionNumber)) {
        return $false
    }
    
    # Create tag
    $tag = New-GitTag -Version $VersionNumber -Message "Release version $VersionNumber"
    if (-not $tag) {
        return $false
    }
    
    # Push to GitHub
    if (-not (Push-ToGitHub)) {
        return $false
    }
    
    # Update release API
    $config = Get-GitHubConfig
    if ($config.Repository) {
        Update-ReleaseAPI -Version $VersionNumber -Repository $config.Repository
        Push-ToGitHub
    }
    
    Write-GitLog "Version $VersionNumber published successfully" -Level Success
    return $true
}

function Invoke-CreateRelease {
    param(
        [string]$VersionNumber,
        [string]$Notes
    )
    
    $config = Get-GitHubConfig
    if (-not $config.Repository) {
        Write-GitLog "Repository not configured. Run setup-repo first." -Level Error
        return $false
    }
    
    if (-not $VersionNumber) {
        $VersionNumber = Get-CurrentVersion
    }
    
    if (-not $Notes) {
        $Notes = Get-ReleaseNotes -Version $VersionNumber
    }
    
    Write-GitLog "Creating GitHub release for version $VersionNumber..." -Level Info
    
    # Create the release
    if (-not (New-GitHubRelease -Version $VersionNumber -ReleaseNotes $Notes -Repository $config.Repository)) {
        return $false
    }
    
    # Add release assets if requested
    if ($CreateAssets) {
        Add-ReleaseAssets -Version $VersionNumber -Repository $config.Repository
    }
    
    Write-GitLog "GitHub release created successfully" -Level Success
    return $true
}

function Invoke-UpdateClients {
    Write-GitLog "Updating client configurations..." -Level Info
    
    $config = Get-GitHubConfig
    if (-not $config.Repository) {
        Write-GitLog "Repository not configured" -Level Error
        return $false
    }
    
    # Test update endpoint
    if (Test-UpdateEndpoint -Repository $config.Repository) {
        Write-GitLog "Update endpoint is functional" -Level Success
        
        # Update launcher configuration
        $launcherPath = Join-Path $script:SourcePath "PCOptimizationLauncher.ps1"
        if (Test-Path $launcherPath) {
            $content = Get-Content $launcherPath -Raw
            $updateUrl = "https://raw.githubusercontent.com/$($config.Repository)/$($script:DefaultBranch)"
            
            $updatedContent = $content -replace '(\$UpdateServer\s*=\s*")[^"]*(")', "`${1}$updateUrl`${2}"
            Set-Content $launcherPath $updatedContent -Encoding UTF8
            
            Write-GitLog "Updated launcher with new server URL" -Level Success
        }
        
        return $true
    }
    else {
        Write-GitLog "Update endpoint test failed" -Level Error
        return $false
    }
}

function Show-RepositoryStatus {
    Write-Host "📊 GitHub Integration Status" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    
    # Git repository status
    if (Test-GitRepository) {
        Write-Host "✅ Git Repository: Initialized" -ForegroundColor Green
        
        try {
            $branch = git branch --show-current
            $status = git status --porcelain
            $remoteUrl = git remote get-url origin 2>$null
            
            Write-Host "🌿 Current Branch: $branch" -ForegroundColor White
            Write-Host "🔗 Remote URL: $(if ($remoteUrl) { $remoteUrl } else { 'Not configured' })" -ForegroundColor White
            Write-Host "📝 Working Directory: $(if ($status) { 'Has changes' } else { 'Clean' })" -ForegroundColor White
        }
        catch {
            Write-Host "⚠️  Error getting Git status" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "❌ Git Repository: Not initialized" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # GitHub CLI status
    if (Test-GitHubCLI) {
        Write-Host "✅ GitHub CLI: Authenticated" -ForegroundColor Green
    }
    else {
        Write-Host "❌ GitHub CLI: Not available or not authenticated" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Configuration status
    $config = Get-GitHubConfig
    if ($config.Repository) {
        Write-Host "✅ Repository: $($config.Repository)" -ForegroundColor Green
        Write-Host "🔄 Auto-Update: $(if ($config.AutoUpdate) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
        Write-Host "🌐 Update Server: $($config.UpdateServer)" -ForegroundColor White
        
        if ($config.LastRelease) {
            Write-Host "🏷️  Last Release: $($config.LastRelease)" -ForegroundColor White
        }
    }
    else {
        Write-Host "❌ Repository: Not configured" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Current version
    $currentVersion = Get-CurrentVersion
    Write-Host "📦 Current Version: $currentVersion" -ForegroundColor White
    
    Write-Host ""
}

#endregion

#region Main Execution

function Show-GitHubBanner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         🐙 PC OPTIMIZATION SUITE - GITHUB INTEGRATION 🐙    ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║     Automated Version Control • Releases • Auto-Updates     ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║                  Streamline Your Distribution                ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
try {
    Show-GitHubBanner
    
    # Set working directory to script location
    Set-Location $script:SourcePath
    
    switch ($Action.ToLower()) {
        "setup-repo" {
            $result = Invoke-SetupRepository
            if ($result) {
                Write-Host ""
                Write-Host "🎉 Repository setup completed!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Create repository on GitHub: https://github.com/new" -ForegroundColor White
                Write-Host "2. Push initial code: git push -u origin main" -ForegroundColor White
                Write-Host "3. Publish first version: .\GitHubIntegration.ps1 -Action publish" -ForegroundColor White
            }
        }
        
        "publish" {
            $result = Invoke-PublishVersion -VersionNumber $Version
            if ($result) {
                Write-Host ""
                Write-Host "🚀 Version published successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "1. Create release: .\GitHubIntegration.ps1 -Action create-release" -ForegroundColor White
                Write-Host "2. Test auto-update: .\GitHubIntegration.ps1 -Action update-clients" -ForegroundColor White
            }
        }
        
        "create-release" {
            $result = Invoke-CreateRelease -VersionNumber $Version -Notes $ReleaseNotes
            if ($result) {
                Write-Host ""
                Write-Host "📦 GitHub release created!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Release URL: https://github.com/$($(Get-GitHubConfig).Repository)/releases" -ForegroundColor Cyan
            }
        }
        
        "update-clients" {
            $result = Invoke-UpdateClients
            if ($result) {
                Write-Host ""
                Write-Host "🔄 Client configurations updated!" -ForegroundColor Green
            }
        }
        
        "status" {
            Show-RepositoryStatus
        }
        
        default {
            Write-GitLog "Unknown action: $Action" -Level Error
            Write-Host ""
            Write-Host "Available actions:" -ForegroundColor Yellow
            Write-Host "• setup-repo    - Initialize GitHub repository" -ForegroundColor White
            Write-Host "• publish       - Publish new version" -ForegroundColor White  
            Write-Host "• create-release - Create GitHub release" -ForegroundColor White
            Write-Host "• update-clients - Update client configurations" -ForegroundColor White
            Write-Host "• status        - Show current status" -ForegroundColor White
        }
    }
}
catch {
    Write-GitLog "Critical error: $($_.Exception.Message)" -Level Error
    Write-Host "❌ Operation failed. Check the error message above." -ForegroundColor Red
    exit 1
}

#endregion