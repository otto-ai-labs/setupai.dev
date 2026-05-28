# windows/modules/languages.ps1
# Step 5: Programming languages — Python 3.12, Python 3.11, uv, Node.js via
# nvm-windows, and Jupyter.
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\languages.ps1"

. "$PSScriptRoot\utils.ps1"

Write-Info "Step 5: Installing programming languages and runtimes..."

# ── Python 3.12 ───────────────────────────────────────────────────────────────

$py312 = Get-Command python3.12 -ErrorAction SilentlyContinue
if ($null -eq $py312) {
    # winget may have installed it but PATH hasn't refreshed — also check registry
    $py312Reg = Get-ItemProperty "HKLM:\SOFTWARE\Python\PythonCore\3.12\InstallPath" `
        -ErrorAction SilentlyContinue
}

if ((Test-CommandExists "python") -and ((python --version 2>&1) -match '3\.12')) {
    Write-Success "Python 3.12 already installed"
}
elseif ($null -ne $py312Reg) {
    Write-Success "Python 3.12 already installed (registry)"
}
else {
    Install-WithWinget -Id "Python.Python.3.12" -Name "Python 3.12" -TimeoutSeconds 300
}

# ── Python 3.11 ───────────────────────────────────────────────────────────────

if ($env:LIGHT -eq "true") {
    Write-Info "Light mode — skipping Python 3.11"
}
else {
    $py311Reg = Get-ItemProperty "HKLM:\SOFTWARE\Python\PythonCore\3.11\InstallPath" `
        -ErrorAction SilentlyContinue
    if ($null -ne $py311Reg) {
        Write-Success "Python 3.11 already installed (registry)"
    }
    else {
        Install-WithWinget -Id "Python.Python.3.11" -Name "Python 3.11" -TimeoutSeconds 300
    }
}

# Upgrade pip for whatever python is on PATH right now
if (Test-CommandExists "python") {
    Write-Info "Upgrading pip..."
    python -m pip install --upgrade pip 2>&1 | Out-Null
    python -m pip install virtualenv 2>&1 | Out-Null
    Write-Success "pip upgraded"
}
elseif (Test-CommandExists "python3") {
    python3 -m pip install --upgrade pip 2>&1 | Out-Null
    python3 -m pip install virtualenv 2>&1 | Out-Null
    Write-Success "pip upgraded"
}

# ── uv — fast Python package and project manager ──────────────────────────────

if (Test-CommandExists "uv") {
    Write-Success "uv already installed ($(uv --version 2>&1))"
}
else {
    Install-WithWinget -Id "astral-sh.uv" -Name "uv" -TimeoutSeconds 120
}

# ── Jupyter — interactive notebooks ──────────────────────────────────────────

if ($env:LIGHT -eq "true") {
    Write-Info "Light mode — skipping Jupyter"
}
else {
    $pipCmd = if (Test-CommandExists "pip") { "pip" }
              elseif (Test-CommandExists "pip3") { "pip3" }
              else { $null }

    if ($null -eq $pipCmd) {
        Write-Warn "pip not found — skipping Jupyter. Install Python first, then: pip install jupyter jupyterlab"
    }
    elseif (Test-CommandExists "jupyter") {
        Write-Success "Jupyter already installed"
    }
    else {
        Write-Info "Installing Jupyter and JupyterLab (this may take a few minutes)..."
        & $pipCmd install jupyter jupyterlab 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Jupyter and JupyterLab installed"
        }
        else {
            Write-Warn "Jupyter install failed — retry: pip install jupyter jupyterlab"
        }
    }
}

# ── Node.js via nvm-windows ───────────────────────────────────────────────────
# nvm-windows: https://github.com/coreybutler/nvm-windows

Write-Info "Installing Node.js via nvm-windows..."

$nvmExe = "$env:APPDATA\nvm\nvm.exe"
$nvmInstalled = (Test-CommandExists "nvm") -or (Test-Path $nvmExe)

if (-not $nvmInstalled) {
    $result = Install-WithWinget -Id "CoreyButler.NVMforWindows" -Name "nvm-windows" -TimeoutSeconds 120
    if ($result) {
        # Refresh PATH so nvm is available in this session
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH", "User")
        Write-Info "nvm-windows installed. You may need to open a new terminal for nvm to be available."
    }
}
else {
    Write-Success "nvm-windows already installed"
}

# Install and use LTS Node if node is not yet available
if (-not (Test-CommandExists "node")) {
    # Give PATH a chance to pick up nvm from the winget install
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (Test-CommandExists "nvm") {
        Write-Info "Installing Node.js LTS via nvm..."
        nvm install lts 2>&1
        nvm use lts   2>&1
        Write-Success "Node.js LTS installed via nvm-windows"
    }
    else {
        Write-Warn "nvm command not yet available — open a new terminal, then run:"
        Write-Warn "  nvm install lts"
        Write-Warn "  nvm use lts"
    }
}
else {
    Write-Success "Node.js already installed ($(node --version 2>&1))"
}

Write-Success "Programming languages installed"
Write-Host ""
