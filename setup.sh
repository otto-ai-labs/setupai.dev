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
#
# Usage:
#   ./setup.sh [--minimal] [--skip-ai-tools] [--skip-databases] [--help]
################################################################################

# Note: We don't use 'set -e' because we want to continue installing other
# packages even if some fail or timeout. Each module handles errors gracefully.

# Keep sudo alive for the duration of the script so long installs don't time out
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Signal to sub-scripts that they are running under setup.sh orchestration
# (suppresses their own sudo keepalive and standalone banners/footers)
export SETUP_RUNNING=1

# ── Resolve script directory (works whether run directly or via curl|bash) ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load shared utilities ────────────────────────────────────────────────────
# shellcheck source=scripts/lib/utils.sh
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# ── Parse flags ─────────────────────────────────────────────────────────────
SKIP_AI_TOOLS=false
SKIP_DATABASES=false
SKIP_WEB=false
MINIMAL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-ai-tools)  SKIP_AI_TOOLS=true ;;
        --skip-databases) SKIP_DATABASES=true ;;
        --minimal)        MINIMAL=true ;;
        --skip-web)       SKIP_WEB=true ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-ai-tools    Skip AI tools (Ollama, Claude Code, Codex CLI)"
            echo "  --skip-databases   Skip database installations"
            echo "  --skip-web         Skip JS web development tools (web.sh)"
            echo "  --minimal          Install only essential tools (languages + shell)"
            echo "  --help             Show this help message"
            echo ""
            echo "Individual scripts (run standalone):"
            echo "  ./bootstrap.sh     Sync dotfiles from this repo to ~"
            echo "  ./brew.sh          Install Homebrew + all packages"
            echo "  ./osx.sh           Apply macOS developer defaults"
            echo "  ./web.sh           Set up JS web development tools"
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

# Export flags so modules can read them
export SKIP_AI_TOOLS SKIP_DATABASES SKIP_WEB MINIMAL

# ── Pre-flight: collect inputs BEFORE exec/tee redirect ─────────────────────
# The tee-based logging below can swallow prompts, making read hang.
echo ""
log_info "========================================="
log_info "Pre-flight: collecting configuration"
log_info "========================================="
read -p "Enter your Git username: " git_username </dev/tty
read -p "Enter your Git email: "    git_email    </dev/tty
echo ""

# Export so git.sh and shell.sh can use them
export git_username git_email

# ── Start logging to file ────────────────────────────────────────────────────
LOGFILE="$HOME/ai-dev-setup_$(date +%Y%m%d_%H%M%S).log"
export LOGFILE
exec > >(tee -a "$LOGFILE") 2>&1

# ── System checks ────────────────────────────────────────────────────────────
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

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

export ARCH ARCH_NAME BREW_PREFIX

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

# ── Helper to source a module ────────────────────────────────────────────────
run_module() {
    local module="$SCRIPT_DIR/scripts/modules/$1"
    if [[ ! -f "$module" ]]; then
        log_error "Module not found: $module"
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$module"
}

# ── Run top-level standalone scripts (SETUP_RUNNING=1 suppresses their banners) ──
# brew.sh: Xcode CLI tools, Homebrew, core packages, Python, Node via nvm
bash "$SCRIPT_DIR/brew.sh"

# ── Run internal modules ──────────────────────────────────────────────────────
run_module languages.sh

if [[ "$MINIMAL" == true ]]; then
    log_info "Minimal mode — skipping AI tools, databases, editors, and apps"
    echo ""
else
    run_module ai.sh
    run_module databases.sh
    run_module editors.sh
    run_module apps.sh
fi

run_module git.sh
run_module shell.sh
run_module macos.sh

# osx.sh: macOS system defaults tuned for developers
bash "$SCRIPT_DIR/osx.sh"

# web.sh: JS/web dev stack (Node, pnpm, TypeScript, ESLint, Vite, Bruno)
if [[ "$SKIP_WEB" == false ]] && [[ "$MINIMAL" == false ]]; then
    bash "$SCRIPT_DIR/web.sh"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
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
