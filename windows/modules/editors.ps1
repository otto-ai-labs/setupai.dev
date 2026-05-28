# windows/modules/editors.ps1
# Step 8: IDEs and editors — installs only what the user selected.
# Selections are read from $env:SEL_EDITORS (comma-separated keys).
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\editors.ps1"

if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) { . "$PSScriptRoot\utils.ps1" }

Write-Info "Step 8: Installing IDEs and editors..."

function Test-EditorSelected {
    param([string]$Key)
    if ([string]::IsNullOrEmpty($env:SEL_EDITORS)) { return $true }
    $keys = $env:SEL_EDITORS -split ","
    return Test-ArrayContains -Array $keys -Value $Key
}

# ── VS Code ───────────────────────────────────────────────────────────────────

if (Test-EditorSelected "vscode") {
    $vscodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $codeCmd    = Test-CommandExists "code"

    if ($codeCmd -or (Test-Path $vscodePath)) {
        Write-Success "Visual Studio Code already installed"
    }
    else {
        Install-WithWinget -Id "Microsoft.VisualStudioCode" -Name "VS Code" -TimeoutSeconds 180
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }

    # Install VS Code extensions
    # Resolve `code` binary — may need full path if PATH hasn't refreshed yet
    $codeExe = if (Test-CommandExists "code") { "code" }
               elseif (Test-Path $vscodePath)  { $vscodePath }
               else { $null }

    if ($null -ne $codeExe) {
        Write-Info "Installing VS Code extensions..."

        $extensions = @(
            "ms-python.python",
            "ms-toolsai.jupyter",
            "anthropic.claude",
            "github.copilot"
        )

        foreach ($ext in $extensions) {
            Write-Info "  Installing extension: $ext"
            & $codeExe --install-extension $ext --force 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "  $ext installed"
            }
            else {
                Write-Warn "  $ext install failed — install manually: code --install-extension $ext"
            }
        }

        Write-Success "VS Code extensions installed"
    }
    else {
        Write-Warn "VS Code CLI not yet available — extensions will be installed on first launch"
        Write-Info "Or install manually after opening VS Code:"
        Write-Info "  code --install-extension ms-python.python"
        Write-Info "  code --install-extension ms-toolsai.jupyter"
        Write-Info "  code --install-extension anthropic.claude"
        Write-Info "  code --install-extension github.copilot"
    }
}

# ── Cursor — AI-native VS Code fork ──────────────────────────────────────────

if (Test-EditorSelected "cursor") {
    # Cursor installs to LocalAppData
    $cursorPath = "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"
    if ((Test-CommandExists "cursor") -or (Test-Path $cursorPath)) {
        Write-Success "Cursor already installed"
    }
    else {
        Install-WithWinget -Id "Anysphere.Cursor" -Name "Cursor" -TimeoutSeconds 180
    }
}

Write-Success "IDEs and editors installed"
Write-Host ""
