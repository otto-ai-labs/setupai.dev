#Requires -Version 5.1
<#
.SYNOPSIS
    AI Dev Setup — Windows one-liner bootstrap.
    Clones the repo then launches setup.ps1.

.DESCRIPTION
    This is the script behind the one-liner:
        irm https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/windows/install.ps1 | iex

    It clones setupai.dev into a temp folder then runs windows\setup.ps1
    so all modules are available on disk. Pass flags by editing the
    $SetupArgs line below, or clone the repo and run setup.ps1 directly.

USAGE
    One-liner (run PowerShell as Administrator):
        irm https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/windows/install.ps1 | iex

    With flags — clone first, then run:
        git clone https://github.com/otto-ai-labs/setupai.dev.git
        cd setupai.dev\windows
        .\setup.ps1 -Light
#>

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "  AI Dev Setup — Windows Bootstrap" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor Cyan
Write-Host ""

# ── Check git ────────────────────────────────────────────────────────────────

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] git is not installed. Install Git first:" -ForegroundColor Red
    Write-Host "  winget install --id Git.Git -e --source winget" -ForegroundColor Yellow
    Write-Host "Then open a new terminal and re-run the one-liner." -ForegroundColor Yellow
    exit 1
}

# ── Clone into temp folder ───────────────────────────────────────────────────

$repoUrl  = "https://github.com/otto-ai-labs/setupai.dev.git"
$cloneDir = Join-Path $env:TEMP "setupai-$(Get-Random)"

Write-Host "[INFO] Cloning setupai.dev into: $cloneDir" -ForegroundColor Cyan
git clone --depth 1 $repoUrl $cloneDir 2>&1

if (-not (Test-Path "$cloneDir\windows\setup.ps1")) {
    Write-Host "[ERROR] Clone failed or setup.ps1 not found." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Starting setup..." -ForegroundColor Cyan
Write-Host ""

# ── Launch setup.ps1 ─────────────────────────────────────────────────────────
# Add flags here if needed, e.g.: -Light, -Minimal, -Yes
# Or clone the repo and run setup.ps1 directly to pass your own flags.

& "$cloneDir\windows\setup.ps1"
