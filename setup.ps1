# Antigravity IDE Environment Sync Script for Windows
# This script copies rules, installs global MCP servers, and registers configuration.

$ErrorActionPreference = "Stop"

Write-Host "Starting Antigravity environment sync..." -ForegroundColor Cyan

# 1. Ensure .gemini directory exists and copy GEMINI.md
$geminiDir = "$HOME\.gemini"
if (-not (Test-Path $geminiDir)) {
    New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    Write-Host "Created directory: $geminiDir" -ForegroundColor Yellow
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceGemini = Join-Path $scriptDir "GEMINI.md"

if (Test-Path $sourceGemini) {
    Copy-Item -Path $sourceGemini -Destination (Join-Path $geminiDir "GEMINI.md") -Force
    Write-Host "✓ Copied GEMINI.md to $geminiDir\GEMINI.md" -ForegroundColor Green
} else {
    Write-Warning "Source GEMINI.md not found in the script directory."
}

# 2. Verify Node.js/npm and install Sequential Thinking MCP globally
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "Installing @modelcontextprotocol/server-sequential-thinking globally via npm..." -ForegroundColor Yellow
    npm install -g @modelcontextprotocol/server-sequential-thinking
    Write-Host "✓ Global MCP package installed." -ForegroundColor Green
} else {
    Write-Warning "npm not found. Please install Node.js first, then run 'npm install -g @modelcontextprotocol/server-sequential-thinking' manually."
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

Write-Host "Sync completed successfully!" -ForegroundColor Green
