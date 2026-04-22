#!/usr/bin/env bash

################################################################################
# bootstrap.sh — Sync SetupAI.dev dotfiles to your home directory (~)
#
# Copies config files from this repo into ~ using rsync.
# Safe by default: asks for confirmation before overwriting anything.
# Use --force / -f to skip the prompt (useful in CI or re-runs).
#
# Usage:
#   ./bootstrap.sh          # interactive — prompts before syncing
#   ./bootstrap.sh --force  # skip confirmation prompt
################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

doSync() {
    rsync \
        --exclude ".git/"           \
        --exclude ".DS_Store"       \
        --exclude ".claude/"        \
        --exclude "bootstrap.sh"    \
        --exclude "setup.sh"        \
        --exclude "brew.sh"         \
        --exclude "osx.sh"          \
        --exclude "web.sh"          \
        --exclude "scripts/"        \
        --exclude "README.md"       \
        --exclude "CONTRIBUTING.md" \
        --exclude "LICENSE"         \
        --exclude "index.html"      \
        --exclude ".editorconfig"   \
        --exclude ".gitignore"      \
        --exclude "*.log"           \
        -avh --no-perms . ~

    # Reload shell config if it exists
    if [ -f "$HOME/.zshrc" ]; then
        # shellcheck disable=SC1091
        source "$HOME/.zshrc" 2>/dev/null || true
        log_success "Shell config reloaded"
    fi

    log_success "Dotfiles synced to ~"
}

# Pull latest changes from git if inside a repo
if git rev-parse --is-inside-work-tree &>/dev/null; then
    log_info "Pulling latest changes from git..."
    git pull origin main 2>/dev/null || true
fi

echo ""
log_info "This will sync dotfiles from $(pwd) to ~"
log_warning "Existing files in ~ will be overwritten."
echo ""

if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    doSync
else
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        doSync
    else
        log_info "Sync cancelled."
        exit 0
    fi
fi
