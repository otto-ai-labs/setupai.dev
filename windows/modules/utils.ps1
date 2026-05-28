# windows/modules/utils.ps1
# Shared utilities — logging helpers, package installers, and interactive
# checkbox menu.  Dot-source this file at the top of every module:
#   . "$PSScriptRoot\..\modules\utils.ps1"
#
# NOTE: This file is idempotent — sourcing it multiple times is harmless.

# ── Logging helpers ───────────────────────────────────────────────────────────

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ── Command existence check ───────────────────────────────────────────────────

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ── Winget installer (idempotent) ─────────────────────────────────────────────
# Usage: Install-WithWinget -Id "Git.Git" -Name "Git"
# Returns $true on success or already-installed, $false on failure.

function Install-WithWinget {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [int]$TimeoutSeconds = 300
    )

    # Check if already installed via winget
    $existing = winget list --id $Id --exact 2>$null | Select-String $Id
    if ($existing) {
        Write-Success "$Name is already installed"
        return $true
    }

    Write-Info "Installing $Name via winget (timeout: ${TimeoutSeconds}s)..."

    $job = Start-Job -ScriptBlock {
        param($id)
        winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements 2>&1
    } -ArgumentList $Id

    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds

    if ($null -eq $completed) {
        Stop-Job  -Job $job
        Remove-Job -Job $job -Force
        Write-Err "$Name installation timed out after ${TimeoutSeconds}s"
        Write-Warn "Install manually: winget install --id $Id"
        return $false
    }

    $output = Receive-Job -Job $job
    Remove-Job -Job $job

    if ($job.State -eq 'Completed' -and ($output -match 'Successfully installed' -or $output -match 'No applicable upgrade')) {
        Write-Success "$Name installed successfully"
        return $true
    }
    elseif ($output -match 'already installed') {
        Write-Success "$Name is already installed"
        return $true
    }
    else {
        Write-Warn "$Name installation may have failed. Output:"
        $output | ForEach-Object { Write-Host "  $_" }
        Write-Warn "Retry manually: winget install --id $Id --exact"
        return $false
    }
}

# ── Scoop installer (idempotent) ──────────────────────────────────────────────
# Usage: Install-WithScoop -Package "redis" -Name "Redis"

function Install-WithScoop {
    param(
        [Parameter(Mandatory)][string]$Package,
        [Parameter(Mandatory)][string]$Name,
        [string]$Bucket = "",
        [int]$TimeoutSeconds = 300
    )

    if (-not (Test-CommandExists "scoop")) {
        Write-Warn "Scoop not found — cannot install $Name. Run setup.ps1 to install Scoop first."
        return $false
    }

    # Check if already installed
    $installed = scoop list 2>$null | Select-String "^$Package\s"
    if ($installed) {
        Write-Success "$Name is already installed (Scoop)"
        return $true
    }

    if ($Bucket -ne "" ) {
        Write-Info "Adding Scoop bucket: $Bucket"
        scoop bucket add $Bucket 2>$null | Out-Null
    }

    Write-Info "Installing $Name via Scoop (timeout: ${TimeoutSeconds}s)..."

    $job = Start-Job -ScriptBlock {
        param($pkg)
        scoop install $pkg 2>&1
    } -ArgumentList $Package

    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds

    if ($null -eq $completed) {
        Stop-Job  -Job $job
        Remove-Job -Job $job -Force
        Write-Err "$Name installation timed out after ${TimeoutSeconds}s"
        Write-Warn "Install manually: scoop install $Package"
        return $false
    }

    $output = Receive-Job -Job $job
    Remove-Job -Job $job

    if ($output -match 'already installed') {
        Write-Success "$Name is already installed"
        return $true
    }
    elseif ($output -match "'$Package' \($") {
        Write-Success "$Name installed successfully"
        return $true
    }
    else {
        # Scoop doesn't always use predictable exit text — check list again
        $check = scoop list 2>$null | Select-String "^$Package\s"
        if ($check) {
            Write-Success "$Name installed successfully"
            return $true
        }
        Write-Warn "$Name Scoop install may have failed. Output:"
        $output | ForEach-Object { Write-Host "  $_" }
        Write-Warn "Retry manually: scoop install $Package"
        return $false
    }
}

# ── npm global package installer (idempotent) ─────────────────────────────────

function Install-NpmGlobal {
    param(
        [Parameter(Mandatory)][string]$Package,
        [Parameter(Mandatory)][string]$Name,
        [string]$CheckCommand = ""
    )

    if (-not (Test-CommandExists "npm")) {
        Write-Warn "npm not found — skipping $Name"
        return $false
    }

    $checkCmd = if ($CheckCommand -ne "") { $CheckCommand } else { $Package }
    if (Test-CommandExists $checkCmd) {
        Write-Success "$Name is already installed"
        return $true
    }

    Write-Info "Installing $Name via npm..."
    npm install -g $Package 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$Name installed"
        return $true
    }
    else {
        Write-Warn "$Name npm install failed — retry: npm install -g $Package"
        return $false
    }
}

# ── Upgrade prompt ────────────────────────────────────────────────────────────

function Invoke-UpgradePrompt {
    param(
        [string]$Name,
        [string]$Version
    )

    Write-Host ""
    Write-Host "[UPGRADE] $Name is already installed ($Version)" -ForegroundColor Yellow

    if ($env:UPGRADE_ALL -eq "true") {
        Write-Host "         Auto-upgrading (--yes)" -ForegroundColor Yellow
        return $true
    }

    $answer = Read-Host "         Upgrade to latest? [y/N]"
    return ($answer -match '^[Yy]$')
}

# ── Interactive checkbox menu ─────────────────────────────────────────────────
# Usage:
#   $selected = Show-CheckboxMenu -Title "AI Tools" `
#       -Subtitle "Pick the tools you want" `
#       -Items @(
#           [pscustomobject]@{ Key="ollama"; Label="Ollama";   Desc="Run LLMs locally"; Default=$true  }
#           [pscustomobject]@{ Key="claude"; Label="Claude";   Desc="Anthropic CLI";    Default=$true  }
#       )
#
# Returns a [string[]] of selected Keys.
#
# Controls:
#   Up/Down arrows  — move cursor
#   Space or Enter  — toggle selection
#   A               — select all
#   N               — deselect all
#   D               — done / confirm
#
# When $env:UPGRADE_ALL eq "true" (--yes flag) or stdin is not interactive,
# returns items whose Default is $true without drawing any UI.

function Show-CheckboxMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Subtitle,
        [Parameter(Mandatory)][object[]]$Items
    )

    $n = $Items.Count

    # Build working state
    $selected = @()
    foreach ($item in $Items) {
        $selected += [bool]$item.Default
    }

    # Non-interactive / --yes mode: return defaults immediately
    if ($env:UPGRADE_ALL -eq "true" -or -not [Console]::IsInputRedirected -eq $false) {
        # Actually check if stdout is a real console
    }
    if (-not [System.Environment]::UserInteractive -or $env:UPGRADE_ALL -eq "true") {
        $result = @()
        for ($i = 0; $i -lt $n; $i++) {
            if ($selected[$i]) { $result += $Items[$i].Key }
        }
        return $result
    }

    $cursor   = 0
    $sep      = "----------------------------------------------------------------"
    $totalLines = $n + 5   # title + subtitle + sep + items + sep + hint

    # Draw function — redraws the entire menu in-place
    function Draw-Menu {
        # Move cursor up to top of menu area
        $up = "`e[$($totalLines)A"
        [Console]::Write($up)

        # Title
        Write-Host "`r  $([char]27)[0;36m$Title$([char]27)[0m" -NoNewline
        Write-Host (" " * [Math]::Max(0, 62 - $Title.Length))

        # Subtitle
        Write-Host "`r  $Subtitle" -NoNewline
        Write-Host (" " * [Math]::Max(0, 62 - $Subtitle.Length))

        # Separator
        Write-Host "`r  $sep"

        for ($i = 0; $i -lt $n; $i++) {
            $item  = $Items[$i]
            $box   = if ($selected[$i]) { "$([char]27)[0;32m[x]$([char]27)[0m" } else { "[ ]" }
            $label = $item.Label.PadRight(24)
            $desc  = $item.Desc

            if ($i -eq $cursor) {
                Write-Host "`r  $([char]27)[1;33m> $box $label$([char]27)[0m $desc" -NoNewline
            }
            else {
                Write-Host "`r    $box $label $desc" -NoNewline
            }
            # Pad to clear any leftover chars from previous longer line
            Write-Host (" " * [Math]::Max(0, 2))
        }

        # Bottom separator
        Write-Host "`r  $sep"
        # Hint line
        Write-Host "`r  $([char]27)[0;90mUp/Down: move  Space/Enter: toggle  D: done  A: all  N: none$([char]27)[0m" -NoNewline
        Write-Host ""
    }

    # Print blank lines to reserve space for the menu
    for ($i = 0; $i -lt $totalLines; $i++) { Write-Host "" }

    Draw-Menu

    # Input loop
    while ($true) {
        $key = [Console]::ReadKey($true)   # $true = suppress echo

        # Arrow keys come as two-part sequences on Windows:
        #   Key.Key == ConsoleKey.UpArrow / DownArrow for VT sequences
        switch ($key.Key) {
            'UpArrow'   { if ($cursor -gt 0)      { $cursor-- };  Draw-Menu }
            'DownArrow' { if ($cursor -lt $n - 1) { $cursor++ };  Draw-Menu }
            'Spacebar'  { $selected[$cursor] = -not $selected[$cursor]; Draw-Menu }
            'Enter'     { $selected[$cursor] = -not $selected[$cursor]; Draw-Menu }
            'D'         { break }
            'A'         { for ($i = 0; $i -lt $n; $i++) { $selected[$i] = $true  }; Draw-Menu }
            'N'         { for ($i = 0; $i -lt $n; $i++) { $selected[$i] = $false }; Draw-Menu }
        }
        # Check char for d/a/n lower case (Key gives uppercase)
        if ($key.KeyChar -eq 'd' -or $key.KeyChar -eq 'D') { break }
        if ($key.KeyChar -eq 'a' -or $key.KeyChar -eq 'A') {
            for ($i = 0; $i -lt $n; $i++) { $selected[$i] = $true  }; Draw-Menu
        }
        if ($key.KeyChar -eq 'n' -or $key.KeyChar -eq 'N') {
            for ($i = 0; $i -lt $n; $i++) { $selected[$i] = $false }; Draw-Menu
        }
    }

    Write-Host ""

    $result = @()
    for ($i = 0; $i -lt $n; $i++) {
        if ($selected[$i]) { $result += $Items[$i].Key }
    }
    return $result
}

# ── Array-contains helper ─────────────────────────────────────────────────────

function Test-ArrayContains {
    param(
        [string[]]$Array,
        [string]$Value
    )
    return ($Array -contains $Value)
}

# ── Ensure Scoop is installed ─────────────────────────────────────────────────
# Call this early in setup.ps1 before any Install-WithScoop calls.

function Install-Scoop {
    if (Test-CommandExists "scoop") {
        Write-Success "Scoop already installed"
        return
    }

    Write-Info "Installing Scoop package manager..."
    try {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Success "Scoop installed"
    }
    catch {
        Write-Err "Scoop installation failed: $_"
        Write-Warn "Install manually: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex"
    }
}
