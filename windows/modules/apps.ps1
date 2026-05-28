# windows/modules/apps.ps1
# Step 9: Productivity apps — installs only what the user selected.
# Selections are read from $env:SEL_APPS (comma-separated keys).
#
# macOS → Windows equivalents:
#   Raycast / Rectangle / AltTab → Microsoft PowerToys (FancyZones, PowerToys Run, etc.)
#   Bartender / Lungo / Shottr   → macOS-only, skipped (Windows notes provided)
#   iTerm2                        → Windows Terminal (winget) noted as alternative to Warp
#   Warp                          → Warpdotdev.Warp (also available on Windows)
#   TablePlus                     → TablePlus Windows version available
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\apps.ps1"

if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) { . "$PSScriptRoot\utils.ps1" }

Write-Info "Step 9: Installing productivity tools..."

function Test-AppSelected {
    param([string]$Key)
    if ([string]::IsNullOrEmpty($env:SEL_APPS)) { return $true }
    $keys = $env:SEL_APPS -split ","
    return Test-ArrayContains -Array $keys -Value $Key
}

# Helper: winget-based app install with existence check
function Install-App {
    param(
        [string]$Key,
        [string]$WingetId,
        [string]$Name,
        [string]$CheckPath = "",       # Optional: exe/dir path to check
        [string]$CheckCommand = "",    # Optional: command to Test-CommandExists
        [int]$TimeoutSeconds = 180
    )

    if (-not (Test-AppSelected $Key)) { return }

    $alreadyInstalled = $false
    if ($CheckCommand -ne "" -and (Test-CommandExists $CheckCommand)) { $alreadyInstalled = $true }
    if ($CheckPath    -ne "" -and (Test-Path $CheckPath))             { $alreadyInstalled = $true }

    if ($alreadyInstalled) {
        Write-Success "$Name already installed"
        return
    }

    Install-WithWinget -Id $WingetId -Name $Name -TimeoutSeconds $TimeoutSeconds
}

# ── Terminal ──────────────────────────────────────────────────────────────────

# Warp — AI terminal (also available on Windows)
Install-App -Key "warp" `
    -WingetId "Warpdotdev.Warp" `
    -Name "Warp" `
    -CheckPath "$env:LOCALAPPDATA\Programs\warp\Warp.exe"

# ── Notes & knowledge ─────────────────────────────────────────────────────────

Install-App -Key "obsidian" `
    -WingetId "Obsidian.Obsidian" `
    -Name "Obsidian" `
    -CheckPath "$env:LOCALAPPDATA\Programs\obsidian\Obsidian.exe"

# ── AI Tools (GUI) ────────────────────────────────────────────────────────────

Install-App -Key "lmstudio" `
    -WingetId "ElementLabs.LMStudio" `
    -Name "LM Studio" `
    -CheckPath "$env:LOCALAPPDATA\Programs\LM Studio\LM Studio.exe" `
    -TimeoutSeconds 300

# ── Database GUI ──────────────────────────────────────────────────────────────

Install-App -Key "dbeaver" `
    -WingetId "dbeaver.dbeaver" `
    -Name "DBeaver Community" `
    -CheckCommand "dbeaver" `
    -CheckPath "$env:ProgramFiles\DBeaver\dbeaver.exe"

# TablePlus — Windows version is available
Install-App -Key "tableplus" `
    -WingetId "TablePlus.TablePlus" `
    -Name "TablePlus" `
    -CheckPath "$env:LOCALAPPDATA\Programs\TablePlus\TablePlus.exe"

# ── PowerToys — replaces Raycast + Rectangle + AltTab on Windows ──────────────
# PowerToys bundles:
#   • PowerToys Run  (Raycast / Spotlight replacement — Alt+Space)
#   • FancyZones     (Rectangle window-snapping replacement)
#   • Alt+Tab (peek) enhancement
#   • Many more productivity utilities

if ((Test-AppSelected "powertoys") -or (Test-AppSelected "raycast") -or
    (Test-AppSelected "rectangle") -or (Test-AppSelected "alt-tab")) {

    $ptPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\PowerToys.exe"
    $ptPath2 = "$env:ProgramFiles\PowerToys\PowerToys.exe"

    if ((Test-Path $ptPath) -or (Test-Path $ptPath2) -or (Test-CommandExists "PowerToys")) {
        Write-Success "Microsoft PowerToys already installed"
    }
    else {
        Write-Info "Installing Microsoft PowerToys (replaces Raycast, Rectangle, AltTab on Windows)..."
        Install-WithWinget -Id "Microsoft.PowerToys" -Name "Microsoft PowerToys" -TimeoutSeconds 180
        Write-Info "PowerToys Run = Raycast equivalent (Alt+Space)"
        Write-Info "FancyZones    = Rectangle equivalent (window snapping)"
        Write-Info "Alt+Tab peek  = AltTab equivalent"
    }
}

Write-Success "Productivity tools installed"
Write-Host ""
