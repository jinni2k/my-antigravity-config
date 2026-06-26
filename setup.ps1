# Antigravity IDE Environment Sync Script for Windows
# This script copies rules, installs global MCP servers, registers configuration, and applies Windows/Antigravity patches dynamically.

$ErrorActionPreference = "Stop"

Write-Host "Starting Antigravity environment sync..." -ForegroundColor Cyan

# Preserve original location and set location
$originalLocation = Get-Location
Set-Location -Path $env:USERPROFILE

# Helper function to run OMA commands in a clean Cwd to avoid EPERM on Windows
function Run-OmaCommand ($argsList) {
    $targetDir = $env:USERPROFILE
    $cmdString = "cd /d `"$targetDir`" && oh-my-agent $argsList"
    cmd.exe /c $cmdString
}

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
$geminiDir = "$env:USERPROFILE\.gemini"
if (-not (Test-Path $geminiDir)) {
    New-Item -ItemType Directory -Path $geminiDir -Force | Out-Null
    Write-Host "Created directory: $geminiDir" -ForegroundColor Yellow
}

# Generate onboarding.json to resolve Antigravity CLI Auth (❌ -> ✅)
$onboardingDir = Join-Path $geminiDir "antigravity-cli\cache"
$onboardingPath = Join-Path $onboardingDir "onboarding.json"
if (-not (Test-Path $onboardingDir)) {
    New-Item -ItemType Directory -Path $onboardingDir -Force | Out-Null
}
'{ "onboardingComplete": true }' | Out-File $onboardingPath -Encoding utf8 -Force
Write-Host "✓ Injected onboarding.json to resolve Antigravity CLI Auth" -ForegroundColor Green

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
    Write-Host "Installing required global npm packages..." -ForegroundColor Yellow
    npm install -g @modelcontextprotocol/server-sequential-thinking oh-my-agent @agentmemory/agentmemory
    Write-Host "✓ Global npm packages installed." -ForegroundColor Green
    
    # Run OMA install in a clean Cwd to avoid EPERM on admin paths
    Write-Host "Initializing oh-my-agent installation status..." -ForegroundColor Yellow
    try {
        Run-OmaCommand "install --global -y" | Out-Null
        Run-OmaCommand "install -y" | Out-Null
        Write-Host "✓ OMA installation status initialized." -ForegroundColor Green
    } catch {
        Write-Warning "Could not run OMA installation automatically: $_"
    }
} else {
    Write-Warning "npm not found. Please install Node.js first, then run 'npm install -g @modelcontextprotocol/server-sequential-thinking oh-my-agent @agentmemory/agentmemory' manually."
}

# 3. Apply critical Windows & Antigravity compatibility patches to oh-my-agent cli.js
$cliPath = ""
$npmRoot = & npm config get prefix

# Detect various candidate locations for oh-my-agent cli.js
$cand1 = Join-Path $npmRoot "node_modules\oh-my-agent\bin\cli.js"
$cand2 = Join-Path $env:USERPROFILE "AppData\Roaming\npm\node_modules\oh-my-agent\bin\cli.js"
$cand3 = Join-Path $env:USERPROFILE "AppData\Local\hermes\node\node_modules\oh-my-agent\bin\cli.js"

if (Test-Path $cand1) { $cliPath = $cand1 }
elseif (Test-Path $cand2) { $cliPath = $cand2 }
elseif (Test-Path $cand3) { $cliPath = $cand3 }

if ($cliPath -and (Test-Path $cliPath)) {
    Write-Host "Applying Windows compatibility patches to oh-my-agent cli.js ($cliPath)..." -ForegroundColor Yellow
    
    # Save a temporary patching node script and run it
    $patchTempScript = Join-Path $env:TEMP "oma_patch.js"
    $patchJSContent = @'
const fs = require('fs');
const cliPath = process.argv[2];

if (fs.existsSync(cliPath)) {
    let content = fs.readFileSync(cliPath, 'utf8');
    let modified = false;

    // 1. Minification-resistant RegExp Du2 Patch
    const du2Regex = /([a-zA-Z0-9_$]+)\s*=\s*\{\s*gemini\s*:\s*\{\s*path\s*:\s*[`'"]\$\{z\}\/\.gemini\/settings\.json[`'"]\s*,\s*type\s*:\s*["']json["']\}\s*,\s*claude\s*:\s*\{\s*path\s*:\s*[`'"]\$\{z\}\/\.claude\.json[`'"]\s*,\s*type\s*:\s*["']json["']\}\s*,\s*codex\s*:\s*\{\s*path\s*:\s*[`'"]\$\{z\}\/\.codex\/config\.toml[`'"]\s*,\s*type\s*:\s*["']toml["']\}\s*\}\s*\[\$\]\s*;/;
    const du2Replacement = '$1={gemini:{path:`${z}/.gemini/settings.json`,type:"json"},claude:{path:`${z}/.claude.json`,type:"json"},codex:{path:`${z}/.codex/config.toml`,type:"toml"},antigravity:{path:`${z}/.gemini/antigravity-cli/settings.json`,type:"json"}}[$];';
    
    if (du2Regex.test(content)) {
        content = content.replace(du2Regex, du2Replacement);
        modified = true;
        console.log('  -> Patched Antigravity settings path mapping');
    }

    // 2. PATH split Patch (Windows delimiter)
    const target2 = '($.PATH??"").split(":")';
    const replacement2 = '($.PATH??"").split(process.platform==="win32"?";":":")';
    if (content.includes(target2)) {
        content = content.replace(target2, replacement2);
        modified = true;
        console.log('  -> Patched PATH splitting delimiter');
    }

    // 3. Minification-resistant RegExp Jt5 spawn Option Patch
    const spawnRegex = /([a-zA-Z0-9_$]+)\s*=\s*([a-zA-Z0-9_$]+)\s*\(\s*([a-zA-Z0-9_$]+)\s*,\s*\[\s*\]\s*,\s*\{\s*detached\s*:\s*!0\s*,\s*cwd\s*:\s*([a-zA-Z0-9_$]+)\(([a-zA-Z0-9_$]+)\)\s*,\s*env\s*:\s*\{\s*\.\.\.([a-zA-Z0-9_$]+)\s*,\s*III_REST_PORT\s*:\s*([a-zA-Z0-9_$]+)\(([a-zA-Z0-9_$]+)\)\}\s*,\s*stdio\s*:\s*["']ignore["']\}\s*\)/;
    const spawnReplacement = '$1=$2($3,[],{detached:!0,shell:process.platform==="win32",cwd:$4($5),env:{...$6,III_REST_PORT:$7($8)},stdio:"ignore"})';
    
    if (spawnRegex.test(content)) {
        content = content.replace(spawnRegex, spawnReplacement);
        modified = true;
        console.log('  -> Patched daemon spawn options');
    }

    if (modified) {
        fs.writeFileSync(cliPath, content, 'utf8');
        console.log('✓ Successfully patched cli.js');
    } else {
        console.log('✓ cli.js already fully patched or target code block changed');
    }
} else {
    console.error('cli.js not found at ' + cliPath);
}
'@
    $patchJSContent | Out-File -FilePath $patchTempScript -Encoding utf8 -Force
    node $patchTempScript $cliPath
    Remove-Item $patchTempScript -Force
} else {
    Write-Warning "Could not find oh-my-agent cli.js to patch automatically."
}

# 4. Ensure antigravity settings.json has mcpServers structure
$agSettingsDir = Join-Path $geminiDir "antigravity-cli"
$agSettingsPath = Join-Path $agSettingsDir "settings.json"
if (-not (Test-Path $agSettingsDir)) {
    New-Item -ItemType Directory -Path $agSettingsDir -Force | Out-Null
}
if (Test-Path $agSettingsPath) {
    try {
        $agSettings = Get-Content $agSettingsPath -Raw | ConvertFrom-Json
        if (-not $agSettings.PSObject.Properties['mcpServers'] -and -not $agSettings.PSObject.Properties['mcp']) {
            $agSettings | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{}) -Force
            $agSettings | ConvertTo-Json -Depth 10 | Out-File $agSettingsPath -Encoding utf8 -Force
            Write-Host "✓ Injected mcpServers config into antigravity settings.json" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to parse/update antigravity settings.json"
    }
} else {
    $skeletonSettings = [PSCustomObject]@{
        enableTelemetry = $false
        showFeedbackSurvey = $false
        mcpServers = [PSCustomObject]@{}
    }
    $skeletonSettings | ConvertTo-Json -Depth 10 | Out-File $agSettingsPath -Encoding utf8 -Force
    Write-Host "✓ Initialized skeleton settings.json for antigravity" -ForegroundColor Green
}

# 5. Automatically download & install iii-engine (required by agentmemory)
$nodePath = ""
if (Get-Command agentmemory -ErrorAction SilentlyContinue) {
    $nodePath = Split-Path (Get-Command agentmemory).Path
} else {
    $nodePath = Join-Path $env:USERPROFILE "AppData\Local\hermes\node"
}
$iiiDest = Join-Path $nodePath "iii.exe"

if (-not (Test-Path $iiiDest)) {
    Write-Host "iii-engine not found. Downloading v0.11.2 for Windows..." -ForegroundColor Yellow
    $iiiUrl = "https://github.com/iii-hq/iii/releases/download/iii/v0.11.2/iii-x86_64-pc-windows-msvc.zip"
    $tempZip = Join-Path $env:TEMP "iii.zip"
    $tempExt = Join-Path $env:TEMP "iii_extracted"
    
    if (Test-Path $tempExt) { Remove-Item $tempExt -Recurse -Force }
    
    try {
        Invoke-WebRequest -Uri $iiiUrl -OutFile $tempZip
        Expand-Archive -Path $tempZip -DestinationPath $tempExt -Force
        if (-not (Test-Path $nodePath)) { New-Item -ItemType Directory -Path $nodePath -Force | Out-Null }
        Copy-Item -Path "$tempExt\iii.exe" -Destination $iiiDest -Force
        Write-Host "✓ iii-engine successfully installed to $iiiDest" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to download iii-engine: $_"
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
        if (Test-Path $tempExt) { Remove-Item $tempExt -Recurse -Force }
    }
} else {
    Write-Host "✓ iii-engine is already installed." -ForegroundColor Green
}

# 6. Safely merge configuration into VS Code globalSettings.json
$appData = [System.Environment]::GetFolderPath('ApplicationData')
$settingsPath = "$appData\Code\User\globalSettings.json"
$settingsDir = Split-Path $settingsPath

if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

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

if (-not $settingsJson.PSObject.Properties['mcpServers']) {
    $settingsJson | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}

$mcpConfig = [PSCustomObject]@{
    command = "npx"
    args = @("-y", "@modelcontextprotocol/server-sequential-thinking")
}
$settingsJson.mcpServers | Add-Member -MemberType NoteProperty -Name "sequential-thinking" -Value $mcpConfig -Force
$settingsJson | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding utf8
Write-Host "✓ Registered MCP server configs in $settingsPath" -ForegroundColor Green

# 7. Register short alias 'sync-ag' in PowerShell profile
try {
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }

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

# 8. Start AgentMemory Daemon securely in the background (using cmd to bypass Cwd lock)
Write-Host "Configuring and starting AgentMemory daemon..." -ForegroundColor Yellow
try {
    # Initialize config in user profile directory
    Run-OmaCommand "memory:setup --port 3111" | Out-Null
    
    # Start process fully detached on Windows
    Start-Process -FilePath "agentmemory" -ArgumentList "--port 3111" -WindowStyle Hidden -ErrorAction SilentlyContinue
    
    # Wait until daemon binds and is reachable (HTTP warm-up loop)
    Write-Host "Waiting for AgentMemory daemon to initialize..." -ForegroundColor Yellow
    $maxAttempts = 15
    $attempt = 1
    $online = $false
    while ($attempt -le $maxAttempts -and -not $online) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:3111" -TimeoutSec 1 -UseBasicParsing -ErrorAction Stop
            $online = $true
        } catch {
            if ($null -ne $_.Exception -and $null -ne $_.Exception.Response) {
                $online = $true
            } else {
                Start-Sleep -Milliseconds 600
                $attempt++
            }
        }
    }
    
    if ($online) {
        Write-Host "✓ AgentMemory background daemon started on port 3111." -ForegroundColor Green
    } else {
        Write-Warning "AgentMemory started but could not confirm online status on port 3111 within timeout."
    }
} catch {
    Write-Warning "Failed to start AgentMemory daemon: $_"
}

# 9. Automatically pull and restore .agents settings from GitHub (force reset and check .git directory)
$agentsDir = Join-Path $env:USERPROFILE ".agents"

# Robust check for broken or invalid .agents repository
if (Test-Path $agentsDir) {
    if (-not (Test-Path (Join-Path $agentsDir ".git"))) {
        Write-Host "Found non-git .agents folder. Re-creating..." -ForegroundColor Yellow
        Remove-Item $agentsDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path $agentsDir)) {
    Write-Host ".agents directory not found. Cloning from GitHub..." -ForegroundColor Yellow
    git clone https://github.com/jinni2k/my-antigravity-config $agentsDir
} else {
    Write-Host "Updating local .agents configurations from GitHub (Forcing Reset)..." -ForegroundColor Yellow
    Push-Location $agentsDir
    git fetch --all
    git reset --hard origin/master
    if ($LASTEXITCODE -ne 0) {
        git reset --hard origin/main
    }
    Pop-Location
}

$syncScript = Join-Path $agentsDir "sync.ps1"
if (Test-Path $syncScript) {
    Write-Host "Syncing oh-my-agent configurations and restoring skills..." -ForegroundColor Yellow
    
    # Invoke sync.ps1 using cmd to prevent Cwd pollution from PowerShell process Cwd
    $cmdString = "cd /d `"$agentsDir`" && powershell -ExecutionPolicy Bypass -File sync.ps1 -Pull"
    cmd.exe /c $cmdString
}

# 10. Resolve OMA project/global state and memory warnings
Write-Host "Initializing system-wide state & memories..." -ForegroundColor Yellow

$globalStateDir = Join-Path $env:USERPROFILE ".agents\state"
if (-not (Test-Path $globalStateDir)) {
    New-Item -ItemType Directory -Path $globalStateDir -Force | Out-Null
}

if (Test-Path ".agents") {
    $projectStateDir = ".agents\state"
    if (-not (Test-Path $projectStateDir)) {
        New-Item -ItemType Directory -Path $projectStateDir -Force | Out-Null
        Write-Host "✓ Created local project state folder: $projectStateDir" -ForegroundColor Green
    }
}

# Run memory schema init in a clean context directory
try {
    Run-OmaCommand "memory:init --force" | Out-Null
    Write-Host "✓ Initialized Serena memory schema in .serena/memories." -ForegroundColor Green
} catch {
    Write-Warning "Could not initialize Serena memory directory: $_"
}

# Restore original location context
Set-Location -Path $originalLocation
Write-Host "✓ Restored original operation context directory ($originalLocation)" -ForegroundColor Green

Write-Host "Sync completed successfully!" -ForegroundColor Green
