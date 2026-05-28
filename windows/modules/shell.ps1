# windows/modules/shell.ps1
# Step 11: Shell configuration — Oh My Posh, Scoop, PowerShell profile, and
# modern CLI aliases (bat, eza, ripgrep, fzf).
#
# macOS equivalents:
#   Oh My Zsh           → Oh My Posh  (cross-platform prompt framework)
#   .zshrc              → $PROFILE    (PowerShell profile)
#   zsh-autosuggestions → PSReadLine  (built into PowerShell 5.1+)
#   zsh-syntax-highlighting → PSReadLine syntax coloring
#   starship            → Oh My Posh (or optionally Starship)
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\shell.ps1"

. "$PSScriptRoot\utils.ps1"

Write-Info "Step 11: Configuring shell..."

# ── Oh My Posh — cross-platform prompt framework ──────────────────────────────

if (Test-CommandExists "oh-my-posh") {
    Write-Success "Oh My Posh already installed"
}
else {
    Write-Info "Installing Oh My Posh (Windows equivalent of Oh My Zsh prompt)..."
    Install-WithWinget -Id "JanDeDobbeleer.OhMyPosh" -Name "Oh My Posh" -TimeoutSeconds 120
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# ── Nerd Font for Oh My Posh icons ───────────────────────────────────────────
# Oh My Posh themes use Nerd Font glyphs. Installs CaskaydiaCove Nerd Font.
# NOTE: After install the user must set it in their terminal's font settings.
$nerdFontInstalled = (Get-Item "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\CaskaydiaCoveNerdFont*" `
    -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0

if ($nerdFontInstalled) {
    Write-Success "CaskaydiaCove Nerd Font already installed"
}
else {
    Write-Info "Installing CaskaydiaCove Nerd Font (required for Oh My Posh icons)..."
    try {
        oh-my-posh font install CascadiaCode 2>&1 | Out-Null
        Write-Success "CascadiaCode Nerd Font installed"
        Write-Info "Set 'CaskaydiaCove Nerd Font' as your terminal font to enable icons."
    }
    catch {
        Write-Warn "Font install failed. Install manually:"
        Write-Warn "  oh-my-posh font install CascadiaCode"
        Write-Warn "  or download from https://www.nerdfonts.com/font-downloads"
    }
}

# ── Modern CLI tools via Scoop ────────────────────────────────────────────────
# bat, eza, ripgrep, fzf, fd — same tools used in the Mac shell config.

$cliTools = @(
    @{ Package = "bat";     Name = "bat (syntax-highlighted cat)" }
    @{ Package = "eza";     Name = "eza (modern ls with colors)" }
    @{ Package = "ripgrep"; Name = "ripgrep (fast grep)" }
    @{ Package = "fzf";     Name = "fzf (fuzzy finder)" }
    @{ Package = "fd";      Name = "fd (fast find)" }
)

foreach ($tool in $cliTools) {
    if (Test-CommandExists $tool.Package) {
        Write-Success "$($tool.Name) already installed"
    }
    else {
        Install-WithScoop -Package $tool.Package -Name $tool.Name -TimeoutSeconds 60
    }
}

# ── PowerShell profile setup ($PROFILE) ──────────────────────────────────────
# Equivalent to appending the ai-dev-setup config block to ~/.zshrc on macOS.

# Ensure the profile directory exists
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Create an empty profile if none exists
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Info "Created new PowerShell profile at: $PROFILE"
}
else {
    Write-Info "Existing PowerShell profile found at: $PROFILE"
    # Backup
    $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $PROFILE $backupPath
    Write-Info "Backed up existing profile to: $backupPath"
}

# Marker to keep the block idempotent
$marker = "# === ai-dev-setup Config ==="

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -match [regex]::Escape($marker)) {
    Write-Info "ai-dev-setup shell config already present in profile — skipping"
}
else {
    # Determine Oh My Posh theme path
    $ompThemePath = "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"

    $lightNote = if ($env:LIGHT -eq "true") {
        "# Light mode — Jupyter aliases skipped`n"
    } else {
        ""
    }

    $jupyterAliases = if ($env:LIGHT -ne "true") {
@"
# Jupyter aliases
Set-Alias jl   jupyter    # jupyter lab
function Start-JupyterLab      { jupyter lab @args }
function Start-JupyterNotebook { jupyter notebook @args }
"@
    } else { "" }

    $block = @"

$marker

# Oh My Posh — cross-platform prompt (equivalent to Oh My Zsh on macOS)
# Customise your theme: oh-my-posh print primary --config <theme-path>
# Browse themes: https://ohmyposh.dev/docs/themes
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$ompThemePath" | Invoke-Expression
}

# PSReadLine — auto-suggestions and syntax highlighting (like zsh plugins)
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#6A6A6A' }
    # Ctrl+F accepts the inline suggestion (like zsh-autosuggestions)
    Set-PSReadLineKeyHandler -Key 'Ctrl+f' -Function ForwardWord
}

# nvm-windows — Node version manager
# nvm is a standalone exe; no shell integration needed beyond having it on PATH.

# uv — Python package manager
`$env:PATH = "`$env:USERPROFILE\.local\bin;`$env:PATH"

# Scoop shims are auto-added to PATH by Scoop's installer.

# Modern CLI aliases (commented-out by default — uncomment what you want)
# Set-Alias ls  eza
# Set-Alias ll  { eza -la @args }
# Set-Alias la  { eza -la @args }
# Set-Alias cat bat
#
# Modern CLI tools installed and available by their actual names:
#   eza      — modern ls with colors, icons, git status
#   bat      — cat with syntax highlighting
#   fd       — faster, simpler find
#   rg       — ripgrep, faster grep
#   fzf      — fuzzy finder

# FZF key bindings (if installed)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # Ctrl+T = fuzzy file search; Ctrl+R = fuzzy history search
    Set-PSReadLineKeyHandler -Key 'Ctrl+t' -ScriptBlock {
        `$file = fzf --height 40% --reverse
        if (`$file) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert(`$file)
        }
    }
}

$jupyterAliases

# Personal overrides — API keys, custom aliases, private config.
# Create `$env:USERPROFILE\.extra.ps1 and it will be loaded here.
if (Test-Path "`$env:USERPROFILE\.extra.ps1") {
    . "`$env:USERPROFILE\.extra.ps1"
}

# === End ai-dev-setup Config ===
"@

    Add-Content -Path $PROFILE -Value $block
    Write-Success "ai-dev-setup shell config added to: $PROFILE"
}

# ── Development directory structure ──────────────────────────────────────────
# Mirrors the macOS ~/Development layout from macos.sh

Write-Info "Creating development directory structure..."
$devDirs = @(
    "$env:USERPROFILE\Development\projects"
    "$env:USERPROFILE\Development\learning"
    "$env:USERPROFILE\Development\tools"
    "$env:USERPROFILE\Development\scripts"
    "$env:USERPROFILE\Development\ai-experiments"
)
foreach ($dir in $devDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Success "Development directories created under $env:USERPROFILE\Development\"

Write-Success "Shell configured"
Write-Info "Reload your profile in the current session: . `$PROFILE"
Write-Host ""
