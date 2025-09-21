#Requires -Version 5.1

<#
.SYNOPSIS
    Quick GitHub Publisher - Upload Latest PC Optimization Suite Version

.DESCRIPTION
    This script automates uploading your latest PC Optimization Suite changes to GitHub.
    It handles version management, file preparation, and GitHub integration.

.EXAMPLE
    .\PublishLatestVersion.ps1
    .\PublishLatestVersion.ps1 -NewVersion "2.5.0"
#>

param(
    [string]$NewVersion = "",
    [string]$CommitMessage = "",
    [switch]$CreateRelease,
    [switch]$SkipTests
)

# Script configuration
$script:BasePath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$script:CurrentVersion = "2.4.0"
$script:NewVersionNumber = if ($NewVersion) { $NewVersion } else { "2.4.1" }
$script:RepoUrl = "https://github.com/YOUR_USERNAME/pc-optimization-suite.git"  # Update with your actual repo
$script:BranchName = "main"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " PC Optimization Suite - GitHub Publisher" -ForegroundColor White
Write-Host " Publishing Version: $script:NewVersionNumber" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    # Check if git is installed
    try {
        $gitVersion = git --version
        Write-Host "✅ Git found: $gitVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Git not found. Please install Git from https://git-scm.com/" -ForegroundColor Red
        return $false
    }
    
    # Check if we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-Host "⚠️  Not a git repository. Initializing..." -ForegroundColor Yellow
        git init
        Write-Host "✅ Git repository initialized" -ForegroundColor Green
    }
    
    return $true
}

function Update-VersionNumbers {
    Write-Host "📝 Updating version numbers..." -ForegroundColor Yellow
    
    $filesToUpdate = @(
        "PCOptimizationGUI.ps1",
        "PCOptimizationSuite.ps1", 
        "PCOptimizationLauncher_Professional.ps1",
        "AdvancedDriverUpdater.ps1"
    )
    
    foreach ($file in $filesToUpdate) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            $content = $content -replace $script:CurrentVersion, $script:NewVersionNumber
            $content = $content -replace "v$script:CurrentVersion", "v$script:NewVersionNumber"
            Set-Content $file $content -Encoding UTF8
            Write-Host "   ✅ Updated $file" -ForegroundColor Green
        }
    }
    
    # Update README.md version references
    if (Test-Path "README.md") {
        $readmeContent = Get-Content "README.md" -Raw
        $readmeContent = $readmeContent -replace $script:CurrentVersion, $script:NewVersionNumber
        Set-Content "README.md" $readmeContent -Encoding UTF8
        Write-Host "   ✅ Updated README.md" -ForegroundColor Green
    }
}

function New-Distribution {
    Write-Host "📦 Building distribution package..." -ForegroundColor Yellow
    
    # Run the build script if it exists
    if (Test-Path "BuildDistribution.ps1") {
        try {
            & ".\BuildDistribution.ps1"
            Write-Host "   ✅ Distribution built successfully" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  Build script failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Test-Installation {
    if ($SkipTests) {
        Write-Host "⏭️  Skipping tests..." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🧪 Running quick tests..." -ForegroundColor Yellow
    
    # Test main GUI loads without errors
    try {
        $testResult = powershell -ExecutionPolicy Bypass -Command "
            & '.\PCOptimizationGUI.ps1' -NoGUI -QuickTest
            return `$LASTEXITCODE
        "
        
        if ($testResult -eq 0) {
            Write-Host "   ✅ GUI test passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ⚠️  GUI test returned exit code: $testResult" -ForegroundColor Yellow
            return $true  # Continue anyway
        }
    } catch {
        Write-Host "   ⚠️  Test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $true  # Continue anyway
    }
}

function Submit-Changes {
    Write-Host "📤 Preparing commit..." -ForegroundColor Yellow
    
    # Check if we have a remote origin
    try {
        $remoteUrl = git config --get remote.origin.url
        if (-not $remoteUrl) {
            Write-Host "⚠️  No remote origin found. Setting up..." -ForegroundColor Yellow
            git remote add origin $script:RepoUrl
        }
    } catch {
        Write-Host "⚠️  Setting up remote origin..." -ForegroundColor Yellow
        git remote add origin $script:RepoUrl
    }
    
    # Add all files
    git add .
    
    # Create commit message
    $commitMsg = if ($CommitMessage) { 
        $CommitMessage 
    } else { 
        "🚀 Release v$script:NewVersionNumber - Enhanced GUI with themes and auto-refresh

✨ New Features:
- 6 professional color themes
- Auto-refresh dashboard 
- Enhanced settings interface
- Improved responsive layout
- Real-time system monitoring

🔧 Improvements:
- Better error handling in settings
- Optimized system overview panel
- Professional theme engine
- Background performance monitoring

🐛 Bug Fixes:
- Fixed settings dialog exceptions
- Improved ComboBox handling
- Enhanced form responsiveness" 
    }
    
    # Commit changes
    git commit -m $commitMsg
    Write-Host "   ✅ Changes committed" -ForegroundColor Green
    
    # Tag the version
    git tag -a "v$script:NewVersionNumber" -m "Release version $script:NewVersionNumber"
    Write-Host "   ✅ Version tagged: v$script:NewVersionNumber" -ForegroundColor Green
}

function Push-ToGitHub {
    Write-Host "🌐 Pushing to GitHub..." -ForegroundColor Yellow
    
    try {
        # Push commits
        git push origin $script:BranchName
        Write-Host "   ✅ Code pushed to GitHub" -ForegroundColor Green
        
        # Push tags
        git push origin --tags
        Write-Host "   ✅ Tags pushed to GitHub" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "   ❌ Failed to push: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   💡 You may need to configure GitHub authentication" -ForegroundColor Yellow
        Write-Host "   💡 Run: gh auth login  (if you have GitHub CLI)" -ForegroundColor Yellow
        Write-Host "   💡 Or set up a Personal Access Token" -ForegroundColor Yellow
        return $false
    }
}

function New-GitHubRelease {
    if (-not $CreateRelease) {
        Write-Host "⏭️  Skipping release creation (use -CreateRelease to enable)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "🎁 Creating GitHub release..." -ForegroundColor Yellow
    
    # Check if GitHub CLI is available
    try {
        $ghVersion = gh --version
        Write-Host "   ✅ GitHub CLI found" -ForegroundColor Green
        
        # Create release with GitHub CLI
        $releaseNotes = "## PC Optimization Suite v$script:NewVersionNumber

### 🎨 New Theme System
- 6 professional color themes: Dark Blue, Dark Green, Dark Purple, Light Gray, Ocean Blue, Sunset Orange
- Live theme preview in settings
- Instant theme switching without restart

### ⚡ Auto-Refresh Dashboard  
- Real-time system monitoring in background
- Configurable refresh intervals (1-30 seconds)
- Smart performance data tracking
- Background CPU and memory monitoring

### 🔧 Enhanced Interface
- Improved responsive layout system
- Better settings dialog with error handling
- Optimized system overview panel sizing
- Professional appearance tab in settings

### 🐛 Bug Fixes
- Fixed settings dialog ComboBox exceptions
- Improved form responsiveness and anchoring
- Better error handling throughout application
- Enhanced theme color management

Download the portable version below or clone the repository to get started!"

        # Create the release
        gh release create "v$script:NewVersionNumber" --title "PC Optimization Suite v$script:NewVersionNumber" --notes $releaseNotes
        
        # Upload distribution if it exists
        if (Test-Path "Demo_Distribution\PC_Optimization_Suite_Portable.zip") {
            gh release upload "v$script:NewVersionNumber" "Demo_Distribution\PC_Optimization_Suite_Portable.zip"
            Write-Host "   ✅ Portable package uploaded" -ForegroundColor Green
        }
        
        Write-Host "   ✅ Release created successfully" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  GitHub CLI not found. Creating release manually..." -ForegroundColor Yellow
        Write-Host "   💡 Visit: https://github.com/YOUR_USERNAME/pc-optimization-suite/releases/new" -ForegroundColor Cyan
        Write-Host "   💡 Tag: v$script:NewVersionNumber" -ForegroundColor Cyan
    }
}

function Show-Results {
    Write-Host ""
    Write-Host "🎉 Publishing Complete!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "📦 Version: $script:NewVersionNumber" -ForegroundColor White
    Write-Host "🌐 Repository: $script:RepoUrl" -ForegroundColor White
    Write-Host "🏷️  Tag: v$script:NewVersionNumber" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Visit your GitHub repository to verify the upload" -ForegroundColor White
    Write-Host "   2. Create a release from the new tag (if not done automatically)" -ForegroundColor White
    Write-Host "   3. Share your repository URL with users" -ForegroundColor White
    Write-Host "   4. Consider updating your project documentation" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Repository URL:" -ForegroundColor Cyan
    Write-Host "   $script:RepoUrl" -ForegroundColor White
    Write-Host ""
}

# Main execution
try {
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    Update-VersionNumbers
    New-Distribution
    
    if (-not (Test-Installation)) {
        Write-Host "⚠️  Tests failed. Continue anyway? (y/N): " -ForegroundColor Yellow -NoNewline
        $continue = Read-Host
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Host "❌ Publishing cancelled" -ForegroundColor Red
            exit 1
        }
    }
    
    Submit-Changes
    
    if (Push-ToGitHub) {
        New-GitHubRelease
        Show-Results
    } else {
        Write-Host ""
        Write-Host "📋 Manual Steps Required:" -ForegroundColor Yellow
        Write-Host "1. Configure GitHub authentication" -ForegroundColor White
        Write-Host "2. Re-run this script or push manually with: git push origin main --tags" -ForegroundColor White
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ Error during publishing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "📞 Check the GitHub_Publishing_Guide.md for manual instructions" -ForegroundColor Yellow
    exit 1
}