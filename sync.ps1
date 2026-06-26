# oh-my-agent Unified GitHub Sync Tool (sync.ps1)
# Usage:
#   .\sync.ps1           : Prompts interactive selection menu
#   .\sync.ps1 -Push     : Immediate push/backup bypass
#   .\sync.ps1 -Pull     : Immediate pull/restore bypass

param (
    [switch]$Push,
    [switch]$Pull
)

# Force UTF-8 coding to prevent Hangul path corruptions on Windows
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Continue" # External CLI stderr shouldn't crash script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

# --- Operation Functions ---

function Backup-Settings {
    Write-Host ""
    Write-Host "📤 [BACKUP] Staging and pushing settings to GitHub..." -ForegroundColor Cyan
    
    git add mcp.json
    git add oma-config.yaml
    git add .gitignore
    git add README.md
    git add sync.ps1
    git add setup.ps1
    if (Test-Path "rules") { git add rules/ }
    if (Test-Path "workflows") { git add workflows/ }

    $CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CommitMsg = "chore(config): Sync settings on $CurrentTime"
    
    $CommitOut = git commit -m $CommitMsg 2>&1
    if ($CommitOut -match "nothing to commit, working tree clean") {
        Write-Host "✅ No local changes detected. Working tree clean." -ForegroundColor Green
    } else {
        Write-Host "🚀 Pushing updates to GitHub..." -ForegroundColor Gray
        git push origin master
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
        } else {
            Write-Warning "Push failed. Retrying on main branch..."
            git push origin main
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Backup completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "❌ Push failed. Check your network or GitHub credentials." -ForegroundColor Red
            }
        }
    }
}

function Restore-Settings {
    Write-Host ""
    Write-Host "📥 [RESTORE] Fetching settings from GitHub..." -ForegroundColor Cyan
    
    git pull origin master
    if ($LASTEXITCODE -ne 0) {
        git pull origin main
    }
    
    Write-Host "🩺 Running oh-my-agent doctor to restore skill modules..." -ForegroundColor Cyan
    Write-Host "💡 Info: Press ENTER when prompted to restore 32 missing skills." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
    
    & oh-my-agent doctor
    
    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "✅ Restore complete! Inside your project workspace, run:" -ForegroundColor Green
    Write-Host "👉   oh-my-agent link" -ForegroundColor Cyan
}

# --- Main Script Logic ---

Write-Host "🛸 [OMA SYNC] Starting unified synchronization tool..." -ForegroundColor Cyan

# Initialize local Git if missing
if (-not (Test-Path ".git")) {
    Write-Host "📦 Initializing local Git repository..." -ForegroundColor Gray
    git init
    git branch -m master
    
    $GitUser = git config user.name
    if (-not $GitUser) {
        Write-Host "👤 Setting default Git user identity locally..." -ForegroundColor Gray
        git config user.name "First Fluke"
        git config user.email "our.first.fluke@gmail.com"
    }
}

# Check if origin remote exists
$Remotes = git remote
$HasOrigin = $Remotes -contains "origin"

if (-not $HasOrigin) {
    Write-Host "⚠️ No GitHub remote origin detected. Initializing automatic setup..." -ForegroundColor Yellow
    
    # Check GitHub CLI login
    Write-Host "🔐 Checking GitHub CLI authentication status..." -ForegroundColor Gray
    $GhStatus = gh auth status 2>&1
    if ($GhStatus -match "Logged in to github.com") {
        Write-Host "✅ GitHub CLI is authenticated." -ForegroundColor Green
    } else {
        Write-Host "⚠️ GitHub CLI not logged in or token expired." -ForegroundColor Yellow
        Write-Host "👉 Browser will open shortly. Please complete authentication..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        gh auth login --hostname github.com -p https -w
    }

    # Staging tracking configuration files
    git add mcp.json
    git add oma-config.yaml
    git add .gitignore
    git add README.md
    git add sync.ps1
    git add setup.ps1
    if (Test-Path "rules") { git add rules/ }
    if (Test-Path "workflows") { git add workflows/ }
    
    git commit -m "chore(config): Initial settings commit" 2>$null
    
    # Automate private repository creation and initial push
    Write-Host "🚀 Creating private GitHub repository 'my-antigravity-config'..." -ForegroundColor Cyan
    gh repo create jinni2k/my-antigravity-config --private --source=. --remote=origin --push
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Private repository created and configurations pushed successfully!" -ForegroundColor Green
        Write-Host "Repo URL: https://github.com/jinni2k/my-antigravity-config" -ForegroundColor Green
        Exit 0
    } else {
        Write-Host "❌ Automated repository creation failed. Please check your GitHub permissions or" -ForegroundColor Red
        Write-Host "run manually: git remote add origin <your-repo-url> and try again." -ForegroundColor Yellow
        Exit 1
    }
}

# Handle Switch parameters
if ($Push) {
    Backup-Settings
    Exit 0
}
if ($Pull) {
    Restore-Settings
    Exit 0
}

# Interactive selection menu
Write-Host ""
Write-Host "================ MENU ================" -ForegroundColor DarkCyan
Write-Host " [1] Backup configurations (Git Push)" -ForegroundColor White
Write-Host " [2] Restore configurations (Git Pull & Doctor)" -ForegroundColor White
Write-Host " [3] Exit" -ForegroundColor White
Write-Host "======================================" -ForegroundColor DarkCyan
$Choice = Read-Host "Select operation number"

if ($Choice -eq "1") {
    Backup-Settings
} elseif ($Choice -eq "2") {
    Restore-Settings
} else {
    Write-Host "🚪 Exiting synchronization tool." -ForegroundColor Gray
}
