<#
.SYNOPSIS
    Simple GitHub Setup and Publishing Tool for PC Optimization Suite

.DESCRIPTION
    Easy-to-use tool for setting up GitHub repository and publishing releases

.EXAMPLE
    .\GitHubSetup.ps1 -Setup
    .\GitHubSetup.ps1 -Publish
#>

param(
    [switch]$Setup,
    [switch]$Publish,
    [switch]$CreateRelease,
    [string]$Version = "2.0.1"
)

function Write-GitLog {
    param([string]$Message, [string]$Level = "Info")
    $colors = @{"Info"="Cyan";"Success"="Green";"Warning"="Yellow";"Error"="Red"}
    Write-Host "[$Level] $Message" -ForegroundColor $colors[$Level]
}

function Show-GitHubBanner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         🐙 PC OPTIMIZATION SUITE - GITHUB PUBLISHER 🐙      ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║              Share Your Software with the World             ║" -ForegroundColor White
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║                   Enable Automatic Updates                  ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-GitInstalled {
    try {
        $gitVersion = git --version 2>$null
        return $null -ne $gitVersion
    }
    catch {
        return $false
    }
}

function Test-GitHubCLI {
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            try {
                $authStatus = gh auth status 2>$null
                return $authStatus -match "Logged in"
            }
            catch {
                return $false
            }
        }
        return $false
    }
    catch {
        return $false
    }
}

function Initialize-GitRepository {
    Write-GitLog "Setting up Git repository..." -Level Info
    
    # Initialize git if not already done
    if (-not (Test-Path ".git")) {
        git init
        Write-GitLog "Git repository initialized" -Level Success
        
        # Create .gitignore
        $gitignoreContent = @"
# Logs
Logs/*.log
Logs/*.json
*.log

# Temporary files
Temp/
*.tmp

# User configurations
Config/user-settings.json

# Build outputs
*Distribution*/
*.zip

# Sensitive data
*token*
*password*
github-config.json
"@
        $gitignoreContent | Set-Content ".gitignore" -Encoding UTF8
        git add .gitignore
        git commit -m "Initial commit with .gitignore"
        Write-GitLog ".gitignore created and committed" -Level Success
    }
    else {
        Write-GitLog "Git repository already exists" -Level Info
    }
}

function Add-ProjectFiles {
    Write-GitLog "Adding project files to Git..." -Level Info
    
    $coreFiles = @(
        "PCOptimizationLauncher.ps1",
        "AdvancedDriverUpdater.ps1",
        "SystemLogger.ps1",
        "PCOptimizationSuite.ps1",
        "DriverUpdaterManager.ps1",
        "DriverUpdaterConfig.ini",
        "README.md",
        "SETUP_GUIDE.md",
        "SimpleDistribution.ps1",
        ".gitignore"
    )
    
    foreach ($file in $coreFiles) {
        if (Test-Path $file) {
            git add $file
            Write-GitLog "Added $file" -Level Info
        }
    }
    
    # Initial commit
    try {
        git commit -m "PC Optimization Suite v$Version - Initial release

Features:
- Advanced driver management and updates
- 8-category system health monitoring  
- Gaming optimization mode
- Automatic update system
- Comprehensive logging and recovery
- Professional distribution packages"
        
        Write-GitLog "Initial commit created" -Level Success
    }
    catch {
        Write-GitLog "Commit may already exist or no changes to commit" -Level Warning
    }
}

function Set-GitHubRemote {
    Write-GitLog "Setting up GitHub remote..." -Level Info
    
    Write-Host ""
    Write-Host "📝 GitHub Repository Setup" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You need to create a repository on GitHub first:" -ForegroundColor White
    Write-Host "1. Go to https://github.com/new" -ForegroundColor Gray
    Write-Host "2. Create a repository (e.g., 'pc-optimization-suite')" -ForegroundColor Gray
    Write-Host "3. Don't initialize with README (we have files already)" -ForegroundColor Gray
    Write-Host ""
    
    $repoUrl = Read-Host "Enter your GitHub repository URL (e.g., https://github.com/username/repo.git)"
    
    if ($repoUrl -and $repoUrl -match "github\.com") {
        try {
            # Remove existing origin if it exists
            try { git remote remove origin 2>$null } catch { }
            
            git remote add origin $repoUrl
            Write-GitLog "GitHub remote added: $repoUrl" -Level Success
            return $repoUrl
        }
        catch {
            Write-GitLog "Error adding remote: $($_.Exception.Message)" -Level Error
            return $null
        }
    }
    else {
        Write-GitLog "Invalid GitHub URL provided" -Level Error
        return $null
    }
}

function Push-ToGitHub {
    Write-GitLog "Pushing to GitHub..." -Level Info
    
    try {
        # Push to main branch
        git branch -M main
        git push -u origin main
        Write-GitLog "Code pushed to GitHub successfully!" -Level Success
        return $true
    }
    catch {
        Write-GitLog "Error pushing to GitHub: $($_.Exception.Message)" -Level Error
        Write-Host ""
        Write-Host "⚠️  If this is your first push, you may need to authenticate:" -ForegroundColor Yellow
        Write-Host "1. Use GitHub CLI: gh auth login" -ForegroundColor Gray
        Write-Host "2. Or use personal access token" -ForegroundColor Gray
        Write-Host "3. Or use GitHub Desktop application" -ForegroundColor Gray
        return $false
    }
}

function New-GitHubRelease {
    param([string]$Version)
    
    Write-GitLog "Creating GitHub release..." -Level Info
    
    if (Test-GitHubCLI) {
        Write-GitLog "Using GitHub CLI to create release..." -Level Info
        
        # Create release notes
        $releaseNotes = @"
# PC Optimization Suite v$Version

## 🚀 Features
- **Advanced Driver Management** - Automatic driver scanning and updates with fallback systems
- **System Optimization** - 8-category health monitoring (CPU, Memory, Disk, Network, Registry, Startup, Services, System Files)
- **Gaming Mode** - Specialized gaming performance optimization
- **Automatic Updates** - Self-updating software with GitHub integration
- **Recovery System** - Intelligent problem detection and recovery recommendations
- **Professional Distribution** - Easy-to-share installer and portable packages

## 🎯 What's New
- Enhanced system optimization algorithms
- Improved driver detection and compatibility
- Better gaming mode optimizations
- Comprehensive logging and reporting
- Professional distribution system

## 📦 Installation
1. Download the PC_Optimization_Suite_Portable.zip
2. Extract and run Launch_PC_Optimizer.bat
3. Follow the setup wizard
4. Enjoy automatic system optimization!

## 🔄 Automatic Updates
This software automatically checks for and installs updates, ensuring you always have the latest optimizations and features.

## 📋 System Requirements
- Windows 10/11 (64-bit recommended)
- PowerShell 5.1 or higher
- Administrator privileges (recommended)
- Internet connection (for updates and drivers)

For detailed documentation, see the README.md file.
"@
        
        try {
            # Create the release
            gh release create "v$Version" --title "PC Optimization Suite v$Version" --notes $releaseNotes
            Write-GitLog "GitHub release created successfully!" -Level Success
            
            # Create and upload distribution package
            Write-GitLog "Creating distribution package for release..." -Level Info
            & .\SimpleDistribution.ps1
            
            # Upload the ZIP file if it exists
            $zipFile = "Demo_Distribution\PC_Optimization_Suite_Portable.zip"
            if (Test-Path $zipFile) {
                gh release upload "v$Version" $zipFile
                Write-GitLog "Distribution package uploaded to release" -Level Success
            }
            
            return $true
        }
        catch {
            Write-GitLog "Error creating release: $($_.Exception.Message)" -Level Error
            return $false
        }
    }
    else {
        Write-GitLog "GitHub CLI not available. Please install it from https://cli.github.com/" -Level Warning
        Write-Host ""
        Write-Host "Alternative: Create release manually on GitHub:" -ForegroundColor Yellow
        Write-Host "1. Go to your repository on GitHub" -ForegroundColor Gray
        Write-Host "2. Click 'Releases' tab" -ForegroundColor Gray
        Write-Host "3. Click 'Create a new release'" -ForegroundColor Gray
        Write-Host "4. Tag: v$Version" -ForegroundColor Gray
        Write-Host "5. Upload the ZIP file from Demo_Distribution folder" -ForegroundColor Gray
        return $false
    }
}

function Show-SuccessMessage {
    param([string]$RepoUrl)
    
    Write-Host ""
    Write-Host "🎉 SUCCESS! Your PC Optimization Suite is now on GitHub! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Repository URL: $RepoUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔄 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. View your repository on GitHub" -ForegroundColor White
    Write-Host "2. Share the repository URL with others" -ForegroundColor White
    Write-Host "3. Users can download from the Releases section" -ForegroundColor White
    Write-Host "4. When you update, run: .\GitHubSetup.ps1 -Publish" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Sharing Instructions for Others:" -ForegroundColor Yellow
    Write-Host "1. Send them your GitHub repository URL" -ForegroundColor White
    Write-Host "2. They go to Releases tab and download latest ZIP" -ForegroundColor White
    Write-Host "3. They extract and run Launch_PC_Optimizer.bat" -ForegroundColor White
    Write-Host "4. They automatically get updates when you publish new versions!" -ForegroundColor White
}

# Main execution
try {
    Show-GitHubBanner
    
    if ($Setup -or (-not $Publish -and -not $CreateRelease)) {
        Write-Host "🚀 Setting up GitHub repository for PC Optimization Suite..." -ForegroundColor Cyan
        Write-Host ""
        
        # Check prerequisites
        if (-not (Test-GitInstalled)) {
            Write-GitLog "Git is not installed. Please install Git first:" -Level Error
            Write-Host "Download from: https://git-scm.com/downloads" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Write-GitLog "Git is installed ✓" -Level Success
        
        if (-not (Test-GitHubCLI)) {
            Write-GitLog "GitHub CLI is not installed (optional but recommended)" -Level Warning
            Write-Host "For best experience, install GitHub CLI from: https://cli.github.com/" -ForegroundColor Yellow
            Write-Host "Then run: gh auth login" -ForegroundColor Yellow
            Write-Host ""
        }
        else {
            Write-GitLog "GitHub CLI is installed and authenticated ✓" -Level Success
        }
        
        # Setup process
        Initialize-GitRepository
        Add-ProjectFiles
        $repoUrl = Set-GitHubRemote
        
        if ($repoUrl) {
            $pushResult = Push-ToGitHub
            
            if ($pushResult) {
                Show-SuccessMessage -RepoUrl $repoUrl
                
                Write-Host ""
                $createRelease = Read-Host "Create first release now? (Y/N) [Y]"
                if ($createRelease -eq '' -or $createRelease -match '^[Yy]') {
                    New-GitHubRelease -Version $Version
                }
            }
        }
    }
    elseif ($Publish) {
        Write-Host "📦 Publishing new version to GitHub..." -ForegroundColor Cyan
        Write-Host ""
        
        # Add updated files
        Add-ProjectFiles
        
        # Push changes
        $pushResult = Push-ToGitHub
        
        if ($pushResult) {
            Write-GitLog "Changes pushed to GitHub successfully!" -Level Success
            
            $createRelease = Read-Host "Create new release for v$Version? (Y/N) [Y]"
            if ($createRelease -eq '' -or $createRelease -match '^[Yy]') {
                New-GitHubRelease -Version $Version
            }
        }
    }
    elseif ($CreateRelease) {
        New-GitHubRelease -Version $Version
    }
    
    Write-Host ""
    Write-Host "✨ GitHub operations completed!" -ForegroundColor Green
    Read-Host "Press Enter to continue"
}
catch {
    Write-GitLog "Error: $($_.Exception.Message)" -Level Error
    Read-Host "Press Enter to exit"
    exit 1
}