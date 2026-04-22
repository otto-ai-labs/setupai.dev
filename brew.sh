#!/usr/bin/env bash

################################################################################
# brew.sh — Install Xcode CLI tools, Homebrew, and all packages
#
# Installs everything needed before running the main setup:
#   - Xcode Command Line Tools
#   - Homebrew (with update + upgrade if already installed)
#   - Core CLI utilities
#   - Python 3.12 + 3.11, uv
#   - Node.js via nvm
#   - Git, shell tools (zsh, starship, completions)
#
# Can be run standalone or is called by setup.sh.
#
# Usage:
#   ./brew.sh
################################################################################

# Keep sudo alive — skip if already managed by setup.sh
if [[ -z "$SETUP_RUNNING" ]]; then
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# Colors and helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

prompt_upgrade() {
    local name="$1"
    local version="$2"
    local answer
    echo -e "${YELLOW}[UPGRADE]${NC} $name is already installed (${version})"
    if [[ "${UPGRADE_ALL:-false}" == true ]]; then
        echo "         Auto-upgrading (--yes)"
        return 0
    fi
    read -r -p "         Upgrade to latest? [y/N] " answer </dev/tty
    [[ "$answer" =~ ^[Yy]$ ]]
}

brew_install() {
    local pkg="$1"
    if brew list "$pkg" &>/dev/null; then
        local ver
        ver=$(brew info --json=v1 "$pkg" 2>/dev/null | grep '"installed"' -A2 | grep '"version"' | head -1 | cut -d'"' -f4)
        if prompt_upgrade "$pkg" "${ver:-installed}"; then
            log_info "Upgrading $pkg..."
            brew upgrade "$pkg" || log_warning "Failed to upgrade $pkg — skipping"
        else
            log_success "$pkg skipped"
        fi
    else
        log_info "Installing $pkg..."
        brew install "$pkg" || log_warning "Failed to install $pkg — skipping"
    fi
}

brew_cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null; then
        local ver
        ver=$(brew info --cask --json=v1 "$pkg" 2>/dev/null | grep '"version"' | head -1 | cut -d'"' -f4)
        if prompt_upgrade "$pkg (cask)" "${ver:-installed}"; then
            log_info "Upgrading $pkg..."
            brew upgrade --cask "$pkg" || log_warning "Failed to upgrade $pkg — skipping"
        else
            log_success "$pkg skipped"
        fi
    else
        log_info "Installing $pkg (cask)..."
        brew install --cask "$pkg" || log_warning "Failed to install $pkg — skipping"
    fi
}

# ── Flags ────────────────────────────────────────────────────────────────────
for arg in "$@"; do
    case $arg in
        --yes|-y) UPGRADE_ALL=true ;;
    esac
done
export UPGRADE_ALL

# ── Architecture ─────────────────────────────────────────────────────────────
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

if [[ -z "$SETUP_RUNNING" ]]; then
    echo ""
    echo "======================================================"
    echo " brew.sh — Homebrew package installer"
    echo "======================================================"
    echo ""
fi

# ── Xcode Command Line Tools ─────────────────────────────────────────────────
log_info "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    log_success "Xcode Command Line Tools already installed"
else
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    log_warning "Complete the Xcode installation popup, then re-run this script."
    exit 0
fi
echo ""

# ── Homebrew ─────────────────────────────────────────────────────────────────
log_info "Checking Homebrew..."
if command_exists brew; then
    log_success "Homebrew already installed — updating..."
    brew update && brew upgrade
else
    log_info "Installing Homebrew..."
    # SECURITY NOTE: Review https://github.com/Homebrew/install before running.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    log_success "Homebrew installed"
fi
echo ""

# ── Core CLI utilities ────────────────────────────────────────────────────────
log_info "Installing core CLI utilities..."
echo "------------------------------------------------------"

# Shell
brew_install git
brew_install zsh
brew_install zsh-completions
brew_install starship

# Modern replacements for standard tools
brew_install bat        # cat with syntax highlighting
brew_install eza        # modern ls
brew_install fd         # faster find
brew_install ripgrep    # faster grep
brew_install fzf        # fuzzy finder

# Data & network
brew_install jq         # JSON processor
brew_install yq         # YAML processor
brew_install wget
brew_install curl

# System utilities
brew_install htop
brew_install tree

echo ""

# ── Python ───────────────────────────────────────────────────────────────────
log_info "Installing Python..."
echo "------------------------------------------------------"
# FIX: Check brew list — macOS ships a stub python3 that satisfies command_exists.
if ! brew list python@3.12 &>/dev/null; then
    brew_install python@3.12
fi
if ! brew list python@3.11 &>/dev/null; then
    brew_install python@3.11
fi

# uv — fast Python package + project manager (replaces pip/poetry/pipenv)
brew_install uv

if command_exists pip3; then
    pip3 install --upgrade pip || true
    pip3 install virtualenv || true
fi
echo ""

# ── Node.js via nvm ──────────────────────────────────────────────────────────
log_info "Installing Node.js via nvm..."
echo "------------------------------------------------------"
if [ ! -d "$HOME/.nvm" ]; then
    # SECURITY NOTE: Review https://github.com/nvm-sh/nvm before running.
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    NVM_VERSION="${NVM_VERSION:-v0.40.1}"   # fallback if GitHub API is unavailable
    log_info "Installing nvm $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
        || log_warning "nvm install failed — visit https://github.com/nvm-sh/nvm to install manually"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists node; then
    nvm install --lts
    nvm use --lts
    log_success "Node.js LTS installed"
else
    log_success "Node.js already installed ($(node --version))"
fi
echo ""

# ── Cleanup ───────────────────────────────────────────────────────────────────
log_info "Cleaning up Homebrew cache..."
brew cleanup
echo ""

if [[ -z "$SETUP_RUNNING" ]]; then
    log_success "======================================================"
    log_success " brew.sh complete!"
    log_success "======================================================"
    echo ""
    log_info "Next: run ./setup.sh for the full AI dev setup."
fi
