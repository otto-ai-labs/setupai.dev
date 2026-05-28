# windows/modules/ai.ps1
# Step 6: AI development tools — installs only what the user selected.
# Selections are read from $env:SEL_AI (comma-separated keys).
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\ai.ps1"

if (-not (Get-Command Write-Info -ErrorAction SilentlyContinue)) { . "$PSScriptRoot\utils.ps1" }

if ($env:SKIP_AI_TOOLS -eq "true") {
    Write-Info "Step 6: Skipping AI tools (--SkipAiTools flag)"
    Write-Host ""
    return
}

Write-Info "Step 6: Installing AI development tools..."

# Refresh PATH so npm/node installed in the languages step are visible
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

if (-not (Test-CommandExists "npm")) {
    Write-Warn "npm not found — skipping npm-based AI tools (Claude Code, Codex CLI)"
    Write-Warn "Open a new terminal after Node.js is installed, then re-run this module."
}

# Helper: is this key in the selections?
function Test-AiSelected {
    param([string]$Key)
    # If SEL_AI env var is not set (standalone / --yes run), install everything
    if ([string]::IsNullOrEmpty($env:SEL_AI)) { return $true }
    $keys = $env:SEL_AI -split ","
    return Test-ArrayContains -Array $keys -Value $Key
}

# ── Ollama — run LLMs locally ─────────────────────────────────────────────────

if (Test-AiSelected "ollama") {
    if (Test-CommandExists "ollama") {
        Write-Success "Ollama already installed ($(ollama --version 2>&1))"
    }
    else {
        Install-WithWinget -Id "Ollama.Ollama" -Name "Ollama" -TimeoutSeconds 300
    }
}

# ── Claude Code — Anthropic AI coding CLI ─────────────────────────────────────

if ((Test-AiSelected "claude") -and (Test-CommandExists "npm")) {
    if (Test-CommandExists "claude") {
        Write-Success "Claude Code already installed ($(claude --version 2>&1))"
    }
    else {
        Install-NpmGlobal -Package "@anthropic-ai/claude-code" -Name "Claude Code" -CheckCommand "claude"
    }
}

# ── OpenAI Codex CLI ──────────────────────────────────────────────────────────

if ((Test-AiSelected "codex") -and (Test-CommandExists "npm")) {
    if (Test-CommandExists "codex") {
        Write-Success "OpenAI Codex CLI already installed"
    }
    else {
        Install-NpmGlobal -Package "@openai/codex" -Name "Codex CLI" -CheckCommand "codex"
    }
}

# ── AWS CLI — Bedrock, SageMaker and other AI services ────────────────────────

if (Test-AiSelected "awscli") {
    if (Test-CommandExists "aws") {
        Write-Success "AWS CLI already installed"
    }
    else {
        Install-WithWinget -Id "Amazon.AWSCLI" -Name "AWS CLI" -TimeoutSeconds 180
    }
}

# ── Terraform — infrastructure as code ───────────────────────────────────────

if (Test-AiSelected "terraform") {
    if (Test-CommandExists "terraform") {
        Write-Success "Terraform already installed"
    }
    else {
        Install-WithWinget -Id "Hashicorp.Terraform" -Name "Terraform" -TimeoutSeconds 120
    }
}

# ── GitHub CLI — manage repos, PRs, issues from the terminal ──────────────────

if (Test-AiSelected "gh") {
    if (Test-CommandExists "gh") {
        Write-Success "GitHub CLI already installed ($((gh --version 2>&1) | Select-Object -First 1))"
    }
    else {
        Install-WithWinget -Id "GitHub.cli" -Name "GitHub CLI" -TimeoutSeconds 120
    }
}

# ── ngrok — expose localhost to the internet ──────────────────────────────────

if (Test-AiSelected "ngrok") {
    if (Test-CommandExists "ngrok") {
        Write-Success "ngrok already installed"
    }
    else {
        Install-WithWinget -Id "ngrok.ngrok" -Name "ngrok" -TimeoutSeconds 120
    }
}

# ── Docker — note only, do not auto-install (requires GUI setup) ───────────────

$dockerDesktop = Test-Path "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
$dockerCmd     = Test-CommandExists "docker"
if ($dockerDesktop -or $dockerCmd) {
    Write-Success "Docker already installed"
}
else {
    Write-Info "Docker: download and install from https://www.docker.com/products/docker-desktop/"
    Write-Warn "Docker requires manual installation — visit docker.com to download Docker Desktop for Windows"
}

Write-Success "AI development tools installed"
Write-Host ""
