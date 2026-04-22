#!/bin/bash

################################################################################
# AI Dev Setup — Mac Setup Script
# One script. AI development, ready to go.
# Supports: Intel (x86_64) and Apple Silicon (arm64)
# Author: otto-ai-labs/setupai.dev contributors
# License: MIT
#
# Run directly:
#   bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh)
################################################################################

# Note: We don't use 'set -e' because we want to continue installing other packages
# even if some fail or timeout. Each installation handles errors gracefully.

# Keep sudo alive for the duration of the script so long installs don't time out
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Custom timeout function for macOS (since 'timeout' command doesn't exist natively)
run_with_timeout() {
    local timeout_duration=$1
    shift
    local command_to_run=("$@")

    "${command_to_run[@]}" &
    local cmd_pid=$!

    local count=0
    while kill -0 $cmd_pid 2>/dev/null; do
        if [ $count -ge $timeout_duration ]; then
            kill -TERM $cmd_pid 2>/dev/null
            sleep 1
            kill -KILL $cmd_pid 2>/dev/null
            wait $cmd_pid 2>/dev/null
            return 124
        fi
        sleep 1
        ((count++))
    done

    wait $cmd_pid
    return $?
}

# Helper function to install brew packages with timeout
# FIX: Increased timeout from 60s to 300s — large packages like python@3.12
#      easily exceed 60s on first install.
brew_install_with_timeout() {
    local timeout_duration=300
    local package="$1"

    log_info "Installing $package (with ${timeout_duration}s timeout)..."

    if run_with_timeout "$timeout_duration" brew install "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}

# Helper function to install brew cask packages with timeout
brew_install_cask_with_timeout() {
    local timeout_duration=300
    local package="$1"

    log_info "Installing $package (cask, with ${timeout_duration}s timeout)..."

    if run_with_timeout "$timeout_duration" brew install --cask "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install --cask $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}

# Parse command line arguments
SKIP_AI_TOOLS=false
SKIP_DATABASES=false
MINIMAL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-ai-tools) SKIP_AI_TOOLS=true ;;
        --skip-databases) SKIP_DATABASES=true ;;
        --minimal) MINIMAL=true ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-ai-tools    Skip AI tools (Ollama, Claude Code, Codex CLI)"
            echo "  --skip-databases   Skip database installations"
            echo "  --minimal          Install only essential tools (languages + shell, no AI tools/databases/apps)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# FIX: Collect interactive inputs BEFORE the exec/tee redirect below.
#      The tee-based logging can swallow or delay prompts, making read hang.
echo ""
log_info "========================================="
log_info "Pre-flight: collecting configuration"
log_info "========================================="
read -p "Enter your Git username: " git_username </dev/tty
read -p "Enter your Git email: " git_email </dev/tty
echo ""

# Setup logging to file (after interactive prompts)
LOGFILE="$HOME/ai-dev-setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    ARCH_NAME="Apple Silicon"
    BREW_PREFIX="/opt/homebrew"
elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH_NAME="Intel"
    BREW_PREFIX="/usr/local"
else
    log_error "Unknown architecture: $ARCH"
    exit 1
fi

# Check macOS version
macos_version=$(sw_vers -productVersion)
macos_major=$(echo "$macos_version" | cut -d. -f1)
if [[ "$macos_major" -lt 11 ]]; then
    log_warning "macOS $macos_version detected. Some tools require macOS 11+"
    log_warning "Consider updating to a newer macOS version for best compatibility"
    read -p "Continue anyway? (y/n) " -n 1 -r </dev/tty
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log_info "========================================="
log_info "AI Dev Setup"
log_info "========================================="
log_info "Architecture: $ARCH_NAME ($ARCH)"
log_info "macOS Version: $macos_version"
log_info "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
log_info "Log file: $LOGFILE"
log_info "========================================="
echo ""

################################################################################
# 1. System Updates
################################################################################
log_info "Step 1: Checking for system updates..."
log_warning "Please ensure you've updated macOS through System Settings first"
echo ""

################################################################################
# 2. Install Xcode Command Line Tools
################################################################################
log_info "Step 2: Installing Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    log_success "Xcode Command Line Tools already installed"
else
    xcode-select --install
    log_warning "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 0
fi
echo ""

################################################################################
# 3. Install Homebrew
################################################################################
log_info "Step 3: Installing Homebrew..."
if command -v brew &>/dev/null; then
    log_success "Homebrew already installed at $(which brew)"
    # FIX: Added upgrade after update to keep existing packages current
    brew update && brew upgrade
else
    # SECURITY NOTE: curl|bash runs the remote script with full user permissions.
    # Review https://github.com/Homebrew/install before running on sensitive machines.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
fi
echo ""

################################################################################
# 4. Install Essential Development Tools
################################################################################
log_info "Step 4: Installing essential development tools..."

if command_exists git; then
    log_success "Git already installed ($(git --version 2>/dev/null))"
else
    brew_install_with_timeout git
fi

log_info "Installing modern shell tools..."
if ! command_exists zsh; then
    brew_install_with_timeout zsh
else
    log_success "zsh already installed"
fi

if ! brew list zsh-completions &>/dev/null; then
    brew_install_with_timeout zsh-completions
else
    log_success "zsh-completions already installed"
fi

if ! command_exists starship; then
    brew_install_with_timeout starship
else
    log_success "starship already installed"
fi

log_info "Installing modern CLI utilities..."
declare -a cli_tools=("bat" "eza" "fd" "ripgrep" "fzf" "jq" "yq" "htop" "tree" "wget" "curl")

for tool in "${cli_tools[@]}"; do
    if ! command_exists "$tool"; then
        brew_install_with_timeout "$tool" || true
    else
        log_success "$tool already installed"
    fi
done

log_success "Essential development tools installed"
echo ""

################################################################################
# 5. Install Programming Languages & Runtimes
################################################################################
log_info "Step 5: Installing programming languages and runtimes..."

# Python
# FIX: Previously skipped both versions if *any* python3 existed (including
#      the macOS App Store stub). Now we check brew list for each version explicitly.
if ! brew list python@3.12 &>/dev/null; then
    log_info "Installing Python 3.12..."
    brew_install_with_timeout python@3.12 || true
else
    log_success "Python 3.12 already installed"
fi

if ! brew list python@3.11 &>/dev/null; then
    log_info "Installing Python 3.11..."
    brew_install_with_timeout python@3.11 || true
else
    log_success "Python 3.11 already installed"
fi

if command_exists pip3; then
    pip3 install --upgrade pip
    pip3 install virtualenv
fi

# uv — fast Python package and project manager (replaces Poetry/pipenv)
if ! command_exists uv; then
    log_info "Installing uv (fast Python package manager)..."
    brew_install_with_timeout uv || true
else
    log_success "uv already installed"
fi

# Jupyter — interactive notebooks for AI/data work
log_info "Installing Jupyter (this may take a few minutes)..."
if command_exists pip3; then
    pip3 install jupyter jupyterlab || true
    log_success "Jupyter and JupyterLab installed"
fi

# Node.js (via nvm) — required for AI CLI tools
log_info "Installing Node.js via nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    # FIX: Fetch latest nvm version dynamically instead of pinning to a specific version.
    # SECURITY NOTE: curl|bash — review https://github.com/nvm-sh/nvm first.
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    log_info "Installing nvm ${NVM_VERSION}..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# FIX: Explicitly source nvm.sh before calling nvm commands — the previous
#      version only exported NVM_DIR, which is not enough to make nvm callable.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists node; then
    nvm install --lts
    nvm use --lts
    log_success "Node.js LTS installed via nvm"
else
    log_success "Node.js already installed ($(node --version))"
fi

log_success "Programming languages installed"
echo ""

if [[ "$MINIMAL" == true ]]; then
    log_info "Minimal installation mode - skipping optional components"
    log_info "Jumping to shell configuration..."
    echo ""
else

################################################################################
# 6. Install AI Development Tools
################################################################################
if [[ "$SKIP_AI_TOOLS" == false ]]; then
    log_info "Step 6: Installing AI development tools..."

    # Ollama — run large language models locally
    if command_exists ollama; then
        log_success "Ollama already installed"
    else
        log_info "Installing Ollama (local LLM runner)..."
        brew_install_with_timeout ollama || true
    fi

    # Claude Code — Anthropic's official AI coding CLI
    # npm must be available (installed via nvm above)
    if command_exists claude; then
        log_success "Claude Code already installed"
    else
        log_info "Installing Claude Code (Anthropic AI coding CLI)..."
        npm install -g @anthropic-ai/claude-code || true
    fi

    # OpenAI Codex CLI
    if command_exists codex; then
        log_success "OpenAI Codex CLI already installed"
    else
        log_info "Installing OpenAI Codex CLI..."
        npm install -g @openai/codex || true
    fi

    # AWS CLI — useful for AI services (Bedrock, SageMaker)
    if command_exists aws; then
        log_success "AWS CLI already installed"
    else
        brew_install_with_timeout awscli || true
    fi

    # Terraform — infrastructure as code
    if command_exists terraform; then
        log_success "Terraform already installed"
    else
        brew tap hashicorp/tap || true
        brew_install_with_timeout hashicorp/tap/terraform || true
    fi

    # Docker — note only, do not auto-install (requires GUI setup)
    if [ -d "/Applications/Docker.app" ]; then
        log_success "Docker already installed"
    else
        log_info "Docker: download and install from https://www.docker.com/products/docker-desktop/"
        log_warning "Docker requires manual installation — visit docker.com to download Docker Desktop"
    fi

    log_success "AI development tools installed"
    echo ""
else
    log_info "Step 6: Skipping AI tools (--skip-ai-tools flag)"
    echo ""
fi

################################################################################
# 7. Install Database Tools
################################################################################
if [[ "$SKIP_DATABASES" == false ]]; then
    log_info "Step 7: Installing database tools..."

    if ! brew list postgresql@15 &>/dev/null; then
        brew_install_with_timeout postgresql@15 || true
    else
        log_success "postgresql@15 already installed"
    fi

    if ! brew list redis &>/dev/null; then
        brew_install_with_timeout redis || true
    else
        log_success "redis already installed"
    fi

    # SQLite — check brew list, not command_exists (/usr/bin/sqlite3 ships with macOS)
    if ! brew list sqlite3 &>/dev/null; then
        brew_install_with_timeout sqlite3 || true
    else
        log_success "sqlite3 already installed"
    fi

    log_success "Database tools installed"
    log_info "Note: Databases are not auto-started. Use 'brew services start <db>' when needed"
    echo ""
else
    log_info "Step 7: Skipping databases (--skip-databases flag)"
    echo ""
fi

################################################################################
# 8. Install IDEs and Editors
################################################################################
log_info "Step 8: Installing IDEs and editors..."

if [ -d "/Applications/Visual Studio Code.app" ]; then
    log_success "Visual Studio Code already installed"
else
    brew_install_cask_with_timeout visual-studio-code || true
fi

# Install VS Code extensions — code CLI is only available after opening VS Code once
if command_exists code; then
    log_info "Installing VS Code extensions..."
    code --install-extension ms-python.python || true
    code --install-extension ms-toolsai.jupyter || true
    code --install-extension anthropic.claude || true
    code --install-extension github.copilot || true
    log_success "VS Code extensions installed"
else
    log_warning "VS Code 'code' CLI not yet available — open VS Code once to enable it"
    log_info "Recommended extensions to install manually:"
    log_info "  - Python (ms-python.python)"
    log_info "  - Jupyter (ms-toolsai.jupyter)"
    log_info "  - Claude (anthropic.claude)"
    log_info "  - GitHub Copilot (github.copilot)"
fi

log_success "IDEs and editors installed"
echo ""

################################################################################
# 9. Install Productivity Tools
################################################################################
log_info "Step 9: Installing productivity tools..."

declare -a cask_apps=("iterm2" "rectangle")
for app in "${cask_apps[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        log_success "$app already installed"
    else
        brew_install_cask_with_timeout "$app" || true
    fi
done

log_success "Productivity tools installed"
echo ""

fi  # End of non-minimal installation

################################################################################
# 10. Configure Git
################################################################################
log_info "Step 10: Configuring Git..."

# git_username and git_email were collected before the tee redirect at the top
git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global core.editor "vim"
git config --global pull.rebase false

# Generate SSH key for Git
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log_info "Generating SSH key for Git..."
    # FIX (optional hardening): Remove -N "" to be prompted for a passphrase,
    #      which is recommended for keys added to GitHub/GitLab.
    #      Keeping -N "" here for non-interactive scripted runs.
    ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    log_success "SSH key generated at ~/.ssh/id_ed25519.pub"
    log_warning "Add this key to your GitHub/GitLab account:"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    log_success "SSH key already exists"
fi

log_success "Git configured"
echo ""

################################################################################
# 11. Configure Shell (zsh with Oh My Zsh)
################################################################################
log_info "Step 11: Configuring shell..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_success "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up existing .zshrc"
fi

if grep -q "^plugins=" "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=.*/plugins=(git python zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
else
    echo 'plugins=(git python zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
fi

if ! grep -q "# === ai-dev-setup Config ===" "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << EOF

# === ai-dev-setup Config ===

# NVM configuration
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"

# Homebrew ($ARCH_NAME)
eval "\$($BREW_PREFIX/bin/brew shellenv)"

# uv — Python package manager
export PATH="\$HOME/.local/bin:\$PATH"

# Starship prompt
# FIX: Added note — run 'starship preset plain-text > ~/.config/starship.toml'
#      or visit https://starship.rs/presets/ to customise your prompt theme.
command -v starship &>/dev/null && eval "\$(starship init zsh)"

# Jupyter aliases
alias jl='jupyter lab'
alias jn='jupyter notebook'

# Aliases - DISABLED to allow both traditional and modern tools to coexist
# Uncomment any aliases you want to use:
# alias ls='eza'
# alias ll='eza -la'
# alias la='eza -la'
# alias cat='bat'
# alias find='fd'
# alias grep='rg'
#
# Modern CLI tools are installed and available by their actual names:
# - eza (modern ls with colors, icons, git status)
# - bat (cat with syntax highlighting)
# - fd (faster, simpler find)
# - rg/ripgrep (faster grep)
# - fzf (fuzzy finder)

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Personal overrides — API keys, custom aliases, private config
# Create ~/.extra and put anything you don't want in version control there
[ -f ~/.extra ] && source ~/.extra

# === End ai-dev-setup Config ===
EOF
    log_success "Custom shell configurations added"
else
    log_info "Custom shell configurations already present, skipping"
fi

log_success "Shell configured"
echo ""

################################################################################
# 12. Create Development Directory Structure
################################################################################
log_info "Step 12: Creating development directory structure..."

mkdir -p "$HOME/Development/"{projects,learning,tools,scripts,ai-experiments}
mkdir -p "$HOME/.config"

log_success "Development directories created"
echo ""

################################################################################
# 13. Performance Optimizations
################################################################################
log_info "Step 13: Applying performance optimizations..."

defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g QLPanelAnimationDuration -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.universalaccess reduceTransparency -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1

log_success "Performance optimizations applied"
log_warning "You may need to restart for all changes to take effect"
echo ""

################################################################################
# 14. Cleanup
################################################################################
log_info "Step 14: Cleaning up Homebrew cache..."
# FIX: Added brew cleanup to reclaim disk space from cached downloads (can be several GB)
brew cleanup
log_success "Homebrew cache cleaned"
echo ""

################################################################################
# Final Steps & Summary
################################################################################
log_success "========================================="
log_success "AI Dev Setup complete!"
log_success "========================================="
echo ""

log_info "Installed versions:"
echo "  Python 3.12: $(${BREW_PREFIX}/opt/python@3.12/bin/python3.12 --version 2>/dev/null || echo 'N/A')"
echo "  Python 3.11: $(${BREW_PREFIX}/opt/python@3.11/bin/python3.11 --version 2>/dev/null || echo 'N/A')"
echo "  Node:        $(node --version 2>/dev/null || echo 'N/A')"
echo "  uv:          $(uv --version 2>/dev/null || echo 'N/A')"
echo "  Jupyter:     $(jupyter --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  Ollama:      $(ollama --version 2>/dev/null || echo 'N/A (if installed)')"
echo "  Claude Code: $(claude --version 2>/dev/null || echo 'N/A (if installed)')"
echo "  Git:         $(git --version 2>/dev/null || echo 'N/A')"
echo ""

log_info "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Add your SSH key to GitHub: cat ~/.ssh/id_ed25519.pub"
echo "  3. Set up your API keys:"
echo "     - Anthropic: export ANTHROPIC_API_KEY='your-key' (get at console.anthropic.com)"
echo "     - OpenAI:    export OPENAI_API_KEY='your-key'    (get at platform.openai.com)"
echo "  4. Try Ollama (run a local AI model): ollama run llama3"
echo "  5. Launch Jupyter: jupyter lab  (or use alias: jl)"
echo "  6. Start coding with Claude Code: claude"
echo "  7. Customise your Starship prompt: https://starship.rs/presets/"
echo "  8. Restart your Mac for all system changes to take effect"
echo ""
log_info "Log saved to: $LOGFILE"
log_info "Happy building! 🤖"
