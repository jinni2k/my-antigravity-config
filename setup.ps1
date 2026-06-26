# Antigravity IDE Environment Sync Script for Windows
# This script copies rules, installs global MCP servers, and registers configuration.

$ErrorActionPreference = "Stop"

Write-Host "Starting Antigravity environment sync..." -ForegroundColor Cyan

# 0. Check and install Antigravity CLI (agy) if not installed
if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
    Write-Host "Antigravity CLI (agy) not found. Installing..." -ForegroundColor Yellow
    try {
        $installScript = Invoke-RestMethod "https://antigravity.google/cli/install.ps1"
        Invoke-Expression $installScript
        Write-Host "✓ Antigravity CLI (agy) installation command executed." -ForegroundColor Green
    } catch {
        Write-Warning "Could not install Antigravity CLI automatically: $_. Please run 'irm https://antigravity.google/cli/install.ps1 | iex' manually."
    }
} else {
    Write-Host "✓ Antigravity CLI (agy) is already installed." -ForegroundColor Green
}

# 1. Ensure .gemini directory exists and copy GEMINI.md
$geminiDir = "$HOME\.gemini"
if (-not (Test-Path $geminiDir)) {
    New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    Write-Host "Created directory: $geminiDir" -ForegroundColor Yellow
}

# Get the script definition path
$scriptPath = $MyInvocation.MyCommand.Definition
$scriptDir = ""
$sourceGemini = ""

# Check if definition is a valid local file path
if ($scriptPath -and (Test-Path $scriptPath -IsValid) -and (Test-Path $scriptPath)) {
    $scriptDir = Split-Path -Parent $scriptPath
    $sourceGemini = Join-Path $scriptDir "GEMINI.md"
}

if ($sourceGemini -and (Test-Path $sourceGemini)) {
    Copy-Item -Path $sourceGemini -Destination (Join-Path $geminiDir "GEMINI.md") -Force
    Write-Host "✓ Copied GEMINI.md from local directory to $geminiDir\GEMINI.md" -ForegroundColor Green
} else {
    Write-Host "Local GEMINI.md not found or running from remote. Downloading from GitHub..." -ForegroundColor Yellow
    $randomVal = Get-Random
    $githubRawUrl = "https://raw.githubusercontent.com/jinni2k/my-antigravity-config/master/GEMINI.md?v=$randomVal"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Encoding = [System.Text.Encoding]::UTF8
        $webClient.DownloadFile($githubRawUrl, (Join-Path $geminiDir "GEMINI.md"))
        Write-Host "✓ Downloaded and saved GEMINI.md from GitHub" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download GEMINI.md from GitHub: $_"
    }
}

# 2. Verify Node.js/npm and install globally via npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "Installing @modelcontextprotocol/server-sequential-thinking and oh-my-agent globally via npm..." -ForegroundColor Yellow
    npm install -g @modelcontextprotocol/server-sequential-thinking oh-my-agent
    Write-Host "✓ Global npm packages installed." -ForegroundColor Green
} else {
    Write-Warning "npm not found. Please install Node.js first, then run 'npm install -g @modelcontextprotocol/server-sequential-thinking oh-my-agent' manually."
}

# 3. Safely merge configuration into globalSettings.json
$appData = [System.Environment]::GetFolderPath('ApplicationData')
$settingsPath = "$appData\Code\User\globalSettings.json"
$settingsDir = Split-Path $settingsPath

if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

# Read existing JSON file or create skeleton object
if (Test-Path $settingsPath) {
    try {
        $settingsContent = Get-Content $settingsPath -Raw
        if ([string]::IsNullOrWhiteSpace($settingsContent)) {
            $settingsJson = [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} }
        } else {
            $settingsJson = $settingsContent | ConvertFrom-Json
        }
    } catch {
        Write-Warning "Could not parse existing settings. Creating backup and initializing new config."
        Copy-Item -Path $settingsPath -Destination "$settingsPath.bak" -Force
        $settingsJson = [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} }
    }
} else {
    $settingsJson = [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} }
}

# Ensure mcpServers property exists
if (-not $settingsJson.PSObject.Properties['mcpServers']) {
    $settingsJson | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}

# Define our target MCP server configuration
$mcpConfig = [PSCustomObject]@{
    command = "npx"
    args = @("-y", "@modelcontextprotocol/server-sequential-thinking")
}

# Add or overwrite the sequential-thinking node
$settingsJson.mcpServers | Add-Member -MemberType NoteProperty -Name "sequential-thinking" -Value $mcpConfig -Force

# Convert back to JSON and write to file
$settingsJson | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8
Write-Host "✓ Registered MCP server configs in $settingsPath" -ForegroundColor Green

# 4. Register short alias 'sync-ag' in PowerShell profile for easier future updates
try {
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $aliasCode = @"

# Antigravity Environment Sync Alias
function Sync-Antigravity {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex (Invoke-RestMethod "https://raw.githubusercontent.com/jinni2k/my-antigravity-config/master/setup.ps1?v=`$(Get-Random)")
}
if (-not (Get-Command sync-ag -ErrorAction SilentlyContinue)) {
    Set-Alias sync-ag Sync-Antigravity -Scope Global
}
"@

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($profileContent) -or $profileContent -notlike "*Sync-Antigravity*") {
        Add-Content -Path $PROFILE -Value $aliasCode
        Write-Host "✓ Registered 'sync-ag' shortcut in your PowerShell profile ($PROFILE)" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not register 'sync-ag' shortcut in profile: $_"
}

# 5. Automatically pull and restore .agents settings from GitHub
$agentsDir = Join-Path $HOME ".agents"
if (-not (Test-Path $agentsDir)) {
    Write-Host ".agents directory not found. Cloning from GitHub..." -ForegroundColor Yellow
    git clone https://github.com/jinni2k/my-antigravity-config $agentsDir
}

$syncScript = Join-Path $agentsDir "sync.ps1"
if (Test-Path $syncScript) {
    Write-Host "Syncing oh-my-agent configurations and restoring skills..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File $syncScript -Pull
}

Write-Host "Sync completed successfully!" -ForegroundColor Green
