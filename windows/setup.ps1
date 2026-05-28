#Requires -Version 5.1
<#
.SYNOPSIS
    AI Dev Setup — Windows Setup Script
    One script. AI development, ready to go on Windows.

.DESCRIPTION
    Windows equivalent of the mac-setup/setup.sh orchestrator.
    Installs AI development tools, languages, databases, editors, and
    productivity apps using Winget (built-in) and Scoop.

    Run directly (PowerShell 7+ recommended, run as Administrator):
        & ([scriptblock]::Create((irm https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/windows/setup.ps1)))

    Or clone and run:
        .\setup.ps1

    Requires: PowerShell 5.1+ (7+ recommended), Windows 10 1809+ or Windows 11
    Must be run as Administrator for some installs (winget, system PATH changes).

.PARAMETER Light
    Lighter install — skips Ollama, AWS CLI, PostgreSQL, DuckDB, VS Code,
    Jupyter, PowerToys, and LM Studio.

.PARAMETER Minimal
    Install only essential tools: languages + shell (Git, Python, Node, uv).

.PARAMETER SkipAiTools
    Skip all AI tool installations (Ollama, Claude Code, Codex CLI, etc.).

.PARAMETER SkipDatabases
    Skip all database installations.

.PARAMETER SkipWeb
    Skip JS/web development tools (pnpm, TypeScript, Vite, etc.).

.PARAMETER Yes
    Auto-answer yes to upgrade prompts for already-installed tools.

.PARAMETER Help
    Show this help message.

.EXAMPLE
    .\setup.ps1
    .\setup.ps1 -Light
    .\setup.ps1 -Minimal
    .\setup.ps1 -SkipDatabases -Yes
#>

# Note: We do NOT set $ErrorActionPreference = 'Stop' — we mirror the bash
# design of continuing even when individual installs fail.
$ErrorActionPreference = 'Continue'

[CmdletBinding()]
param(
    [switch]$Light,
    [switch]$Minimal,
    [switch]$SkipAiTools,
    [switch]$SkipDatabases,
    [switch]$SkipWeb,
    [switch]$Yes,
    [switch]$Help
)

# ── Help ──────────────────────────────────────────────────────────────────────

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# ── Resolve script directory ───────────────────────────────────────────────────

$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent

# ── Load shared utilities ─────────────────────────────────────────────────────

. "$ScriptDir\modules\utils.ps1"

# ── Version check ─────────────────────────────────────────────────────────────

$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Write-Host "[ERROR] PowerShell 5.1 or higher is required. Current: $psVersion" -ForegroundColor Red
    Write-Host "Download PowerShell 7: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
    exit 1
}
if ($psVersion.Major -lt 7) {
    Write-Host "[WARNING] PowerShell 5.1 detected. PowerShell 7+ is recommended for best compatibility." -ForegroundColor Yellow
    Write-Host "         Download: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
    Write-Host ""
}

# ── Administrator check ───────────────────────────────────────────────────────

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin) {
    Write-Warn "This script is NOT running as Administrator."
    Write-Warn "Some installations (winget, system PATH changes, services) require Administrator."
    Write-Warn ""
    Write-Warn "To relaunch as Administrator, run:"
    Write-Warn "  Start-Process powershell -Verb RunAs -ArgumentList '-File ""$($MyInvocation.MyCommand.Path)""'"
    Write-Host ""
    $continue = Read-Host "Continue anyway without Administrator? [y/N]"
    if ($continue -notmatch '^[Yy]$') {
        exit 1
    }
}

# ── Windows version check ─────────────────────────────────────────────────────

$winVer = [System.Environment]::OSVersion.Version
if ($winVer.Major -lt 10) {
    Write-Warn "Windows $($winVer) detected. Windows 10 (1809+) or Windows 11 is required for winget."
    Write-Warn "Some tools may not install correctly."
}
else {
    # Check winget is available (ships with Windows 10 1809+ / Windows 11)
    if (-not (Test-CommandExists "winget")) {
        Write-Warn "winget not found. Install 'App Installer' from the Microsoft Store:"
        Write-Warn "  https://www.microsoft.com/store/productId/9NBLGGH4NNS1"
        Write-Warn "Then re-run this script."
        exit 1
    }
}

# ── Export flags as environment variables ─────────────────────────────────────
# Modules read these rather than function parameters for simplicity.

$env:LIGHT           = if ($Light)          { "true" } else { "false" }
$env:MINIMAL         = if ($Minimal)        { "true" } else { "false" }
$env:SKIP_AI_TOOLS   = if ($SkipAiTools)    { "true" } else { "false" }
$env:SKIP_DATABASES  = if ($SkipDatabases)  { "true" } else { "false" }
$env:SKIP_WEB        = if ($SkipWeb)        { "true" } else { "false" }
$env:UPGRADE_ALL     = if ($Yes)            { "true" } else { "false" }

# ── Pre-flight: collect Git identity ─────────────────────────────────────────
# All interactive prompts happen BEFORE Start-Transcript so they are visible.

Write-Host ""
Write-Info "========================================="
Write-Info "  AI Dev Setup — Pre-flight"
Write-Info "========================================="
Write-Host ""

$env:GIT_USERNAME = Read-Host "  Enter your Git username"
$env:GIT_EMAIL    = Read-Host "  Enter your Git email"
Write-Host ""

# ── Tool selection checkboxes ─────────────────────────────────────────────────
# All interactive UI must happen before Start-Transcript (transcript can
# interfere with [Console]::ReadKey).

if ($Minimal -eq $false) {

    Write-Host ""
    Write-Info "========================================="
    Write-Info "  Select tools to install"
    Write-Info "  (Up/Down move · Space/Enter toggle · D done · A all · N none)"
    Write-Info "========================================="
    Write-Host ""

    # Light-mode defaults — heavy tools default to off
    $dOllama    = if ($Light) { $false } else { $true  }
    $dAwsCli    = $false   # off by default in both modes
    $dPostgres  = if ($Light) { $false } else { $true  }
    $dDuckdb    = $false   # off by default in both modes
    $dVscode    = if ($Light) { $false } else { $true  }
    $dPowerToys = if ($Light) { $false } else { $true  }
    $dLmStudio  = if ($Light) { $false } else { $true  }
    $dDbeaver   = if ($Light) { $false } else { $true  }
    $dTablePlus = $false   # off by default

    # ── AI Tools ───────────────────────────────────────────────────────────────
    $aiItems = @(
        [pscustomobject]@{ Key="ollama";    Label="Ollama";       Desc="Run LLMs locally — Llama, Mistral, Gemma (no API key needed)"; Default=$dOllama }
        [pscustomobject]@{ Key="claude";    Label="Claude Code";  Desc="Anthropic AI coding CLI (needs ANTHROPIC_API_KEY)";            Default=$true   }
        [pscustomobject]@{ Key="codex";     Label="Codex CLI";    Desc="OpenAI coding CLI (needs OPENAI_API_KEY)";                     Default=$true   }
        [pscustomobject]@{ Key="awscli";    Label="AWS CLI";      Desc="Access Bedrock, SageMaker and other AWS AI services";          Default=$dAwsCli }
        [pscustomobject]@{ Key="terraform"; Label="Terraform";    Desc="Infrastructure as code for AI deployments";                    Default=$false  }
        [pscustomobject]@{ Key="gh";        Label="GitHub CLI";   Desc="Manage repos, PRs and issues from the terminal";               Default=$true   }
        [pscustomobject]@{ Key="ngrok";     Label="ngrok";        Desc="Expose localhost to the internet for webhooks and demos";      Default=$false  }
    )
    $selAi = Show-CheckboxMenu -Title "AI Tools" `
        -Subtitle "Tools for building and running AI applications" `
        -Items $aiItems
    $env:SEL_AI = ($selAi -join ",")

    # ── Databases ──────────────────────────────────────────────────────────────
    $dbItems = @(
        [pscustomobject]@{ Key="postgresql"; Label="PostgreSQL";  Desc="Most popular open-source relational database";                  Default=$dPostgres }
        [pscustomobject]@{ Key="redis";      Label="Redis";       Desc="In-memory cache, queues, and session store (via Scoop)";        Default=$true      }
        [pscustomobject]@{ Key="sqlite";     Label="SQLite";      Desc="Lightweight embedded database — great for local AI apps";       Default=$true      }
        [pscustomobject]@{ Key="duckdb";     Label="DuckDB";      Desc="Fast in-process analytical DB — SQL on files, no server";      Default=$dDuckdb   }
    )
    $selDb = Show-CheckboxMenu -Title "Databases" `
        -Subtitle "Local databases for development (not auto-started)" `
        -Items $dbItems
    $env:SEL_DB = ($selDb -join ",")

    # ── Editors ────────────────────────────────────────────────────────────────
    $editorItems = @(
        [pscustomobject]@{ Key="vscode";  Label="VS Code"; Desc="Popular free editor with Python, Jupyter, Claude and Copilot"; Default=$dVscode }
        [pscustomobject]@{ Key="cursor";  Label="Cursor";  Desc="AI-native VS Code fork with built-in chat and autocomplete";   Default=$true    }
    )
    $selEditors = Show-CheckboxMenu -Title "Editors" `
        -Subtitle "Code editors — pick one or both" `
        -Items $editorItems
    $env:SEL_EDITORS = ($selEditors -join ",")

    # ── Productivity Apps ──────────────────────────────────────────────────────
    $appItems = @(
        [pscustomobject]@{ Key="warp";      Label="Warp";         Desc="AI terminal with natural language commands (Windows beta)";     Default=$true       }
        [pscustomobject]@{ Key="lmstudio";  Label="LM Studio";    Desc="GUI app to run local AI models — no terminal needed";           Default=$dLmStudio  }
        [pscustomobject]@{ Key="obsidian";  Label="Obsidian";     Desc="Local markdown notes and knowledge base";                       Default=$true       }
        [pscustomobject]@{ Key="dbeaver";   Label="DBeaver";      Desc="Universal database GUI for Postgres, SQLite and more";          Default=$dDbeaver   }
        [pscustomobject]@{ Key="tableplus"; Label="TablePlus";    Desc="Fast native database GUI (Windows version available)";          Default=$dTablePlus }
        [pscustomobject]@{ Key="powertoys"; Label="PowerToys";    Desc="Replaces Raycast + Rectangle + AltTab — Run, FancyZones, more"; Default=$dPowerToys }
    )
    $selApps = Show-CheckboxMenu -Title "Productivity Apps" `
        -Subtitle "GUI apps and Windows utilities" `
        -Items $appItems
    $env:SEL_APPS = ($selApps -join ",")

    # ── Web / JS Tools ─────────────────────────────────────────────────────────
    $webItems = @(
        [pscustomobject]@{ Key="web"; Label="Full web stack"; Desc="pnpm, TypeScript, ESLint, Biome, Vite, Vercel CLI"; Default=$true }
    )
    $selWeb = Show-CheckboxMenu -Title "Web & JS Tools" `
        -Subtitle "JavaScript/TypeScript development stack" `
        -Items $webItems
    $env:SEL_WEB = ($selWeb -join ",")

    Write-Host ""
    Write-Info "Selections saved — starting installation..."
    Write-Host ""
}

# ── Start transcript logging ──────────────────────────────────────────────────
# Start-Transcript captures all output to a log file.
# Interactive prompts and ReadKey calls happen BEFORE this point.

$logFile = "$env:USERPROFILE\ai-dev-setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append
Write-Info "Logging to: $logFile"

# ── System info banner ─────────────────────────────────────────────────────────

$cpuName  = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
$ramGB    = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$winBuild = (Get-CimInstance Win32_OperatingSystem).Caption

Write-Info "========================================="
Write-Info "AI Dev Setup — Windows"
if ($Light)   { Write-Info "Mode: Light (--Light)" }
if ($Minimal) { Write-Info "Mode: Minimal (--Minimal)" }
Write-Info "========================================="
Write-Info "OS:  $winBuild"
Write-Info "CPU: $cpuName"
Write-Info "RAM: ${ramGB} GB"
Write-Info "PS:  $($psVersion.ToString())"
Write-Info "Log: $logFile"
Write-Info "========================================="
Write-Host ""

# ── Helper: dot-source a module ───────────────────────────────────────────────

function Invoke-Module {
    param([string]$ModuleName)
    $modulePath = "$ScriptDir\modules\$ModuleName"
    if (-not (Test-Path $modulePath)) {
        Write-Err "Module not found: $modulePath"
        return
    }
    . $modulePath
}

# ── Install Scoop early — several modules depend on it ───────────────────────

Install-Scoop

# ── Run modules ───────────────────────────────────────────────────────────────

Invoke-Module "languages.ps1"

if ($Minimal) {
    Write-Info "Minimal mode — skipping AI tools, databases, editors, and apps"
    Write-Host ""
}
else {
    if (-not $SkipAiTools)   { Invoke-Module "ai.ps1"        }
    if (-not $SkipDatabases) { Invoke-Module "databases.ps1" }
    Invoke-Module "editors.ps1"
    Invoke-Module "apps.ps1"
}

Invoke-Module "git.ps1"
Invoke-Module "shell.ps1"

# ── Web / JS tools ────────────────────────────────────────────────────────────

$runWeb = $false
if ((-not $SkipWeb) -and (-not $Minimal)) {
    if ($Yes -or ($env:SEL_WEB -split "," | Where-Object { $_ -eq "web" })) {
        $runWeb = $true
    }
}

if ($runWeb) {
    Write-Info "Installing Web & JS tools..."

    # Refresh PATH so npm is available
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (Test-CommandExists "npm") {
        # pnpm
        if (-not (Test-CommandExists "pnpm")) {
            npm install -g pnpm 2>&1
            Write-Success "pnpm installed"
        } else { Write-Success "pnpm already installed" }

        # TypeScript
        if (-not (Test-CommandExists "tsc")) {
            npm install -g typescript 2>&1
            Write-Success "TypeScript installed"
        } else { Write-Success "TypeScript already installed" }

        # ESLint
        if (-not (Test-CommandExists "eslint")) {
            npm install -g eslint 2>&1
            Write-Success "ESLint installed"
        } else { Write-Success "ESLint already installed" }

        # Vite (local project tool — no global install needed; note only)
        Write-Info "Vite: install per-project with: npm create vite@latest"

        # Vercel CLI
        if (-not (Test-CommandExists "vercel")) {
            npm install -g vercel 2>&1
            Write-Success "Vercel CLI installed"
        } else { Write-Success "Vercel CLI already installed" }
    }
    else {
        Write-Warn "npm not found — skipping web tools. Open a new terminal after Node install."
    }

    Write-Host ""
}

# ── Refresh PATH for version checks ──────────────────────────────────────────

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Info "========================================="
Write-Info "AI Dev Setup complete!"
Write-Info "========================================="
Write-Host ""
Write-Info "Installed versions:"

$versions = [ordered]@{
    "Python 3.12" = { (python --version 2>&1) -replace 'Python ', '' }
    "Python 3.11" = { try { (py -3.11 --version 2>&1) -replace 'Python ', '' } catch { "N/A" } }
    "Node"        = { node --version 2>&1 }
    "npm"         = { npm --version 2>&1 }
    "uv"          = { (uv --version 2>&1) -replace 'uv ', '' }
    "Git"         = { (git --version 2>&1) -replace 'git version ', '' }
    "gh"          = { (gh --version 2>&1 | Select-Object -First 1) -replace 'gh version ', '' }
    "Claude Code" = { claude --version 2>&1 }
    "ngrok"       = { ngrok --version 2>&1 }
}

if ($Light -eq $false) {
    $versions["Jupyter"]   = { (jupyter --version 2>&1 | Select-Object -First 1) }
    $versions["Ollama"]    = { ollama --version 2>&1 }
    $versions["DuckDB"]    = { duckdb --version 2>&1 }
}

foreach ($kv in $versions.GetEnumerator()) {
    try {
        $ver = & $kv.Value
        if ([string]::IsNullOrWhiteSpace($ver)) { $ver = "N/A" }
    }
    catch {
        $ver = "N/A"
    }
    Write-Host ("  {0,-14} {1}" -f ($kv.Key + ":"), $ver)
}

Write-Host ""

# ── Next steps banner ─────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  +------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  IMPORTANT: Open a NEW terminal window before        |" -ForegroundColor Cyan
if ($Light) {
Write-Host "  |  running claude or node commands.                    |" -ForegroundColor Cyan
} else {
Write-Host "  |  running claude, ollama, or jupyter.                 |" -ForegroundColor Cyan
}
Write-Host "  |                                                      |" -ForegroundColor Cyan
Write-Host "  |  Or reload your profile: . `$PROFILE                 |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

Write-Info "Next steps:"
Write-Host "  1. *** Open a NEW terminal (required for PATH to update) ***"
Write-Host "  2. Run: claude            <- start Claude Code"
if ($Light -eq $false) {
    Write-Host "  3. Run: ollama run llama3 <- run a local AI model"
    Write-Host "  4. Run: jupyter lab       <- open Jupyter"
}
Write-Host ""
Write-Info "If any command is still not found after reopening terminal:"
Write-Host "  claude  -> npm install -g @anthropic-ai/claude-code"
if ($Light -eq $false) {
    Write-Host "  ollama  -> winget install Ollama.Ollama"
}
Write-Host "  node    -> . `$PROFILE  (or open new terminal)"
Write-Host ""
Write-Host "  Set your API keys (add to `$env:USERPROFILE\.extra.ps1):"
Write-Host "    `$env:ANTHROPIC_API_KEY = 'sk-ant-...'   # console.anthropic.com"
Write-Host "    `$env:OPENAI_API_KEY    = 'sk-...'        # platform.openai.com"
Write-Host ""
Write-Host "  Customise your prompt: https://ohmyposh.dev/docs/themes"
Write-Host "  Restart Windows for all system changes to take effect"
Write-Host ""

Write-Info "Log saved to: $logFile"
Write-Info "Happy building!"

Stop-Transcript
