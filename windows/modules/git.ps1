# windows/modules/git.ps1
# Step 10: Git configuration and SSH key generation.
# Expects $env:GIT_USERNAME and $env:GIT_EMAIL to be set by setup.ps1.
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\git.ps1"

. "$PSScriptRoot\utils.ps1"

Write-Info "Step 10: Configuring Git..."

# ── Ensure Git is installed ───────────────────────────────────────────────────

if (-not (Test-CommandExists "git")) {
    Write-Info "Git not found — installing..."
    Install-WithWinget -Id "Git.Git" -Name "Git" -TimeoutSeconds 120

    # Refresh PATH so git is available in this session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not (Test-CommandExists "git")) {
        Write-Err "Git installation failed or PATH not updated. Open a new terminal and re-run."
        return
    }
}
else {
    Write-Success "Git already installed ($(git --version 2>&1))"
}

# ── Global git config ─────────────────────────────────────────────────────────

if ([string]::IsNullOrWhiteSpace($env:GIT_USERNAME) -or [string]::IsNullOrWhiteSpace($env:GIT_EMAIL)) {
    Write-Warn "Git username or email not set — skipping git config"
    Write-Warn "Run manually:"
    Write-Warn "  git config --global user.name  'Your Name'"
    Write-Warn "  git config --global user.email 'you@example.com'"
}
else {
    git config --global user.name  $env:GIT_USERNAME
    git config --global user.email $env:GIT_EMAIL
    Write-Success "Git user.name  = $($env:GIT_USERNAME)"
    Write-Success "Git user.email = $($env:GIT_EMAIL)"
}

git config --global init.defaultBranch main
git config --global core.editor       "code --wait"   # VS Code as default editor on Windows
git config --global pull.rebase       false
git config --global core.autocrlf     true            # Windows line-ending normalisation

# ── SSH key generation ────────────────────────────────────────────────────────
# ssh-keygen ships with Windows 10/11 (OpenSSH optional feature) and Git for Windows.

$sshKeyPath = "$env:USERPROFILE\.ssh\id_ed25519"
$sshDir     = "$env:USERPROFILE\.ssh"

if (Test-Path $sshKeyPath) {
    Write-Success "SSH key already exists at $sshKeyPath"
    Write-Info "Public key:"
    Get-Content "$sshKeyPath.pub"
}
else {
    Write-Info "Generating SSH key for Git..."

    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    $email = if ($env:GIT_EMAIL -ne "") { $env:GIT_EMAIL } else { "user@example.com" }

    # -N "" = empty passphrase (same as mac-setup default)
    # Remove -N "" or replace with a passphrase for higher security on shared machines.
    ssh-keygen -t ed25519 -C $email -f $sshKeyPath -N "" 2>&1

    if (Test-Path $sshKeyPath) {
        Write-Success "SSH key generated at $sshKeyPath.pub"

        # Add key to ssh-agent (Windows OpenSSH agent service)
        $sshAgent = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
        if ($null -ne $sshAgent) {
            if ($sshAgent.Status -ne "Running") {
                try {
                    Start-Service ssh-agent
                    Write-Info "ssh-agent service started"
                }
                catch {
                    Write-Warn "Could not start ssh-agent service: $_"
                }
            }
            ssh-add $sshKeyPath 2>&1 | Out-Null
            Write-Success "SSH key added to ssh-agent"
        }
        else {
            Write-Warn "ssh-agent service not found."
            Write-Info "Enable it: Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent"
            Write-Info "Then:      ssh-add $sshKeyPath"
        }

        Write-Host ""
        Write-Warn "Add this public key to your GitHub/GitLab account:"
        Write-Host "  https://github.com/settings/ssh/new" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Public key contents:" -ForegroundColor Yellow
        Get-Content "$sshKeyPath.pub"
        Write-Host ""
    }
    else {
        Write-Warn "SSH key generation failed."
        Write-Warn "Generate manually: ssh-keygen -t ed25519 -C '$email'"
    }
}

Write-Success "Git configured"
Write-Host ""
