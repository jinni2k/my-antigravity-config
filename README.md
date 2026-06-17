# Antigravity IDE Environment Sync

This repository contains the global configuration files and rules for the Antigravity IDE. It allows you to synchronize your settings, custom rules (`GEMINI.md`), and Model Context Protocol (MCP) servers across different machines.

## Files included

*   **`GEMINI.md`**: Your global agent instructions, conventions, and sequential thinking rules.
*   **`setup.ps1`**: A PowerShell script that automates the deployment process on Windows.

---

## How to Upload to GitHub (Initial Machine)

1. Create a new repository on GitHub (e.g., named `my-antigravity-config`).
2. Open your terminal in this `antigravity-config` directory, and run:
   ```bash
   git init
   git add .
   git commit -m "Initialize antigravity settings sync"
   git branch -M main
   git remote add origin https://github.com/[YOUR_GITHUB_ID]/my-antigravity-config.git
   git push -u origin main
   ```
   *(Be sure to replace `[YOUR_GITHUB_ID]` with your actual GitHub username).*

---

## How to Restore on Another Machine (One-Click Setup)

On any new Windows machine, simply open **PowerShell** and run the following command to download, install, and configure everything automatically.

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/[YOUR_GITHUB_ID]/my-antigravity-config.git/main/setup.ps1'))
```

### What the script does:
1. Creates `C:\Users\[username]\.gemini\` directory and downloads `GEMINI.md` into it.
2. Installs the official `sequential-thinking` MCP server package globally.
3. Automatically merges and registers the MCP configurations in your global `%APPDATA%\Code\User\globalSettings.json` file without modifying other existing servers.
