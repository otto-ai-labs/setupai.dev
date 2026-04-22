#!/usr/bin/env bash

################################################################################
# web.sh — JavaScript web development setup
#
# Installs and configures a modern JS/web development environment:
#   - Node.js LTS via nvm (if not already installed)
#   - Core npm global tools: TypeScript, ESLint, Prettier, Vite
#   - Package manager: pnpm
#   - API development: Bruno (open-source Postman alternative)
#
# Can be run standalone or after brew.sh / setup.sh.
#
# Usage:
#   ./web.sh
################################################################################

# Keep sudo alive — skip if already managed by setup.sh
if [[ -z "$SETUP_RUNNING" ]]; then
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

command_exists() { command -v "$1" &>/dev/null; }

npm_global_install() {
    local pkg="$1"
    local cmd="${2:-$1}"   # optional: command name if different from package name
    if command_exists "$cmd"; then
        log_success "$pkg already installed ($(${cmd} --version 2>/dev/null || echo 'ok'))"
    else
        log_info "Installing $pkg globally..."
        npm install -g "$pkg" || log_warning "Failed to install $pkg — skipping"
    fi
}

if [[ -z "$SETUP_RUNNING" ]]; then
    echo ""
    echo "======================================================"
    echo " web.sh — JavaScript web development setup"
    echo "======================================================"
    echo ""
fi

# ── Node.js via nvm ──────────────────────────────────────────────────────────
log_info "Checking Node.js..."
echo "------------------------------------------------------"

# Source nvm if already installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists nvm; then
    log_info "Installing nvm..."
    # SECURITY NOTE: Review https://github.com/nvm-sh/nvm before running.
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

if ! command_exists node; then
    log_info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default node
    log_success "Node.js LTS installed ($(node --version))"
else
    log_success "Node.js already installed ($(node --version))"
    log_info "Setting LTS as default..."
    nvm alias default node 2>/dev/null || true
fi

log_success "npm version: $(npm --version 2>/dev/null || echo 'N/A')"
echo ""

# ── pnpm — fast, disk-efficient package manager ───────────────────────────────
log_info "Installing pnpm..."
echo "------------------------------------------------------"
if command_exists pnpm; then
    log_success "pnpm already installed ($(pnpm --version))"
else
    npm install -g pnpm || log_warning "pnpm install failed — skipping"
fi
echo ""

# ── TypeScript ────────────────────────────────────────────────────────────────
log_info "Installing TypeScript toolchain..."
echo "------------------------------------------------------"
npm_global_install typescript tsc
npm_global_install ts-node
npm_global_install tsx
echo ""

# ── Linting & formatting ──────────────────────────────────────────────────────
log_info "Installing linting and formatting tools..."
echo "------------------------------------------------------"
npm_global_install eslint
npm_global_install prettier
npm_global_install "@biomejs/biome" biome
echo ""

# ── Build tools ───────────────────────────────────────────────────────────────
log_info "Installing build tools..."
echo "------------------------------------------------------"
npm_global_install vite
npm_global_install turbo
npm_global_install vercel
echo ""

# ── Utilities ─────────────────────────────────────────────────────────────────
log_info "Installing dev utilities..."
echo "------------------------------------------------------"
npm_global_install serve          # local static file server
npm_global_install http-server    # zero-config HTTP server
npm_global_install nodemon        # auto-restart on file changes
npm_global_install concurrently   # run multiple npm scripts in parallel
npm_global_install dotenv-cli dotenv   # load .env files from the CLI
echo ""

# ── API client ────────────────────────────────────────────────────────────────
log_info "Installing Bruno (open-source API client)..."
echo "------------------------------------------------------"
if command_exists brew && ! brew list --cask bruno &>/dev/null; then
    brew install --cask bruno || log_warning "Bruno install failed — download from https://www.usebruno.com"
else
    log_success "Bruno already installed"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
if [[ -z "$SETUP_RUNNING" ]]; then
    echo ""
    log_success "======================================================"
    log_success " web.sh complete!"
    log_success "======================================================"
    echo ""
    log_info "Installed versions:"
    echo "  Node.js:    $(node --version 2>/dev/null || echo 'N/A')"
    echo "  npm:        $(npm --version 2>/dev/null || echo 'N/A')"
    echo "  pnpm:       $(pnpm --version 2>/dev/null || echo 'N/A')"
    echo "  TypeScript: $(tsc --version 2>/dev/null || echo 'N/A')"
    echo "  ESLint:     $(eslint --version 2>/dev/null || echo 'N/A')"
    echo "  Prettier:   $(prettier --version 2>/dev/null || echo 'N/A')"
    echo "  Vite:       $(vite --version 2>/dev/null || echo 'N/A')"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Create a new project:  pnpm create vite@latest my-app"
    echo "  3. Or start with Next.js: pnpm create next-app@latest my-app"
fi
