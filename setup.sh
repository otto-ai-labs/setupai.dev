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

# ── Resolve script directory ─────────────────────────────────────────────────
# When run via `bash <(curl ...)`, BASH_SOURCE[0] resolves to /dev/fd/N —
# a file descriptor, not a real path — so relative sources and bash sub-scripts
# all fail. Detect this case, clone the full repo, and re-exec from disk.
if [[ "${BASH_SOURCE[0]}" == /dev/fd/* ]] || [[ "${BASH_SOURCE[0]}" == /proc/self/fd/* ]]; then
    REPO_URL="https://github.com/otto-ai-labs/setupai.dev.git"
    TMP_DIR="$(mktemp -d)"
    echo "[INFO] Running via curl — cloning repo to $TMP_DIR ..."
    git clone --depth=1 "$REPO_URL" "$TMP_DIR" 2>&1 | grep -v "^$"
    echo "[INFO] Re-executing setup from cloned repo..."
    exec bash "$TMP_DIR/setup.sh" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load shared utilities ────────────────────────────────────────────────────
# shellcheck source=scripts/lib/utils.sh
source "$SCRIPT_DIR/scripts/lib/utils.sh"

# ── Parse flags ─────────────────────────────────────────────────────────────
SKIP_AI_TOOLS=false
SKIP_DATABASES=false
SKIP_WEB=false
MINIMAL=false
UPGRADE_ALL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-ai-tools)  SKIP_AI_TOOLS=true ;;
        --skip-databases) SKIP_DATABASES=true ;;
        --minimal)        MINIMAL=true ;;
        --skip-web)       SKIP_WEB=true ;;
        --yes|-y)         UPGRADE_ALL=true ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --yes, -y          Auto-upgrade all already-installed tools (no prompts)"
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

# Export flags so modules and sub-scripts can read them
export SKIP_AI_TOOLS SKIP_DATABASES SKIP_WEB MINIMAL UPGRADE_ALL

# ── Pre-flight: collect inputs BEFORE exec/tee redirect ─────────────────────
# The tee-based logging below can swallow prompts, making read hang.
echo ""
log_info "========================================="
log_info "  AI Dev Setup — Pre-flight"
log_info "========================================="
echo ""
read -p "  Enter your Git username: " git_username </dev/tty
read -p "  Enter your Git email:    " git_email    </dev/tty
echo ""

# Export so git.sh and shell.sh can use them
export git_username git_email

# ── Tool selection (skipped in --minimal or --yes mode) ──────────────────────
# All interactive prompts must happen here, before exec/tee swallows the tty.

if [[ "$MINIMAL" == false ]]; then

    echo ""
    log_info "========================================="
    log_info "  Select tools to install"
    log_info "  (Up/Down move · Space/Enter toggle · D done · A all · N none)"
    log_info "========================================="
    echo ""

    # ── AI Tools ─────────────────────────────────────────────────────────────
    SEL_AI=()
    while IFS= read -r _line; do SEL_AI+=("$_line"); done < <(checkbox_select \
        "AI Tools" "Tools for building and running AI applications" \
        "ollama|Ollama|Run LLMs locally — Llama, Mistral, Gemma (no API key needed)|on" \
        "claude|Claude Code|Anthropic AI coding CLI (needs ANTHROPIC_API_KEY)|on" \
        "codex|Codex CLI|OpenAI coding CLI (needs OPENAI_API_KEY)|on" \
        "awscli|AWS CLI|Access Bedrock, SageMaker and other AWS AI services|off" \
        "terraform|Terraform|Infrastructure as code for AI deployments|off" \
        "gh|GitHub CLI|Manage repos, PRs and issues from the terminal|on" \
        "ngrok|ngrok|Expose localhost to the internet for webhooks & demos|off" \
    )

    # ── Databases ────────────────────────────────────────────────────────────
    SEL_DB=()
    while IFS= read -r _line; do SEL_DB+=("$_line"); done < <(checkbox_select \
        "Databases" "Local databases for development (not auto-started)" \
        "postgresql|PostgreSQL 15|Most popular open-source relational database|on" \
        "redis|Redis|In-memory cache, queues, and session store|on" \
        "sqlite|SQLite|Lightweight embedded database — great for local AI apps|on" \
        "duckdb|DuckDB|Fast in-process analytical DB — SQL on files, no server|off" \
    )

    # ── Editors ──────────────────────────────────────────────────────────────
    SEL_EDITORS=()
    while IFS= read -r _line; do SEL_EDITORS+=("$_line"); done < <(checkbox_select \
        "Editors" "Code editors — pick one or both" \
        "vscode|VS Code|Popular free editor with Python, Jupyter, Claude & Copilot|on" \
        "cursor|Cursor|AI-native VS Code fork with built-in chat & autocomplete|on" \
    )

    # ── Productivity Apps ─────────────────────────────────────────────────────
    SEL_APPS=()
    while IFS= read -r _line; do SEL_APPS+=("$_line"); done < <(checkbox_select \
        "Productivity Apps" "GUI apps and Mac utilities" \
        "raycast|Raycast|AI-powered Spotlight replacement with clipboard history|on" \
        "warp|Warp|AI terminal with natural language commands|on" \
        "lmstudio|LM Studio|GUI app to run local AI models — no terminal needed|on" \
        "iterm2|iTerm2|Classic terminal emulator with tabs & split panes|on" \
        "rectangle|Rectangle|Snap windows with keyboard shortcuts|on" \
        "obsidian|Obsidian|Local markdown notes and knowledge base|on" \
        "dbeaver|DBeaver|Universal database GUI for Postgres, SQLite and more|on" \
        "tableplus|TablePlus|Fast native Mac database GUI|off" \
        "alt-tab|AltTab|Windows-style app switcher with live previews|on" \
        "bartender|Bartender|Organise and hide menu bar icons|off" \
        "lungo|Lungo|Keep Mac awake during long installs or downloads|on" \
        "shottr|Shottr|Fast screenshot tool with annotations and OCR|on" \
    )

    # ── Web / JS Tools ────────────────────────────────────────────────────────
    SEL_WEB=()
    while IFS= read -r _line; do SEL_WEB+=("$_line"); done < <(checkbox_select \
        "Web & JS Tools" "JavaScript/TypeScript development stack (web.sh)" \
        "web|Full web stack|pnpm, TypeScript, ESLint, Biome, Vite, Vercel CLI, Bruno|on" \
    )

    echo ""
    log_success "Selections saved — starting installation..."
    echo ""

fi

# Export selections so modules can read them
export SEL_AI SEL_DB SEL_EDITORS SEL_APPS SEL_WEB

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
# TODO: disabled until interactive tool selection is implemented
# bash "$SCRIPT_DIR/osx.sh"

# web.sh: JS/web dev stack (Node, pnpm, TypeScript, ESLint, Vite, Bruno)
_run_web=false
if [[ "$SKIP_WEB" == false ]] && [[ "$MINIMAL" == false ]]; then
    if [[ "${UPGRADE_ALL:-false}" == true ]] || array_contains SEL_WEB "web"; then
        _run_web=true
    fi
fi
if [[ "$_run_web" == true ]]; then
    bash "$SCRIPT_DIR/web.sh"
fi

# ── Reload nvm into current session so version checks work ───────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ── Summary ──────────────────────────────────────────────────────────────────
log_success "========================================="
log_success "AI Dev Setup complete!"
log_success "========================================="
echo ""

log_info "Installed versions:"
echo "  Python 3.12: $(${BREW_PREFIX}/opt/python@3.12/bin/python3.12 --version 2>/dev/null || echo 'N/A')"
echo "  Python 3.11: $(${BREW_PREFIX}/opt/python@3.11/bin/python3.11 --version 2>/dev/null || echo 'N/A')"
echo "  Node:        $(node --version 2>/dev/null || echo 'N/A')"
echo "  npm:         $(npm --version 2>/dev/null || echo 'N/A')"
echo "  uv:          $(uv --version 2>/dev/null || echo 'N/A')"
echo "  Jupyter:     $(jupyter --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  Ollama:      $(ollama --version 2>/dev/null || echo 'N/A')"
echo "  Claude Code: $(claude --version 2>/dev/null || echo 'N/A')"
echo "  Git:         $(git --version 2>/dev/null || echo 'N/A')"
echo "  gh:          $(gh --version 2>/dev/null | head -1 || echo 'N/A')"
echo "  ngrok:       $(ngrok --version 2>/dev/null || echo 'N/A')"
echo "  duckdb:      $(duckdb --version 2>/dev/null || echo 'N/A')"
echo ""

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  IMPORTANT: Open a NEW terminal window before       ║"
echo "  ║  running claude, ollama, or jupyter.                ║"
echo "  ║                                                      ║"
echo "  ║  Or run:  source ~/.zshrc                           ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""

log_info "Next steps:"
echo "  1. *** Open a NEW terminal window (required for PATH to update) ***"
echo "  2. Run: claude          ← start Claude Code"
echo "  3. Run: ollama run llama3  ← run a local AI model"
echo "  4. Run: jupyter lab     ← open Jupyter (or use alias: jl)"
echo ""
log_info "If any command is still not found after reopening terminal:"
echo "  claude  → npm install -g @anthropic-ai/claude-code"
echo "  ollama  → brew install ollama"
echo "  node    → source ~/.zshrc"
echo ""
echo "  - Set your API keys (add to ~/.extra):"
echo "      export ANTHROPIC_API_KEY='sk-ant-...'  # console.anthropic.com"
echo "      export OPENAI_API_KEY='sk-...'         # platform.openai.com"
echo "  - Customise your prompt: https://starship.rs/presets/"
echo "  - Restart your Mac for all system changes to take effect"
echo ""
log_info "Log saved to: $LOGFILE"
log_info "Happy building!"

# ── Reload shell so all tools are immediately available ──────────────────────
# setup.sh runs in bash, so we can't source ~/.zshrc directly.
# Instead, hand off to a new interactive zsh session which loads ~/.zshrc
# automatically — the user lands in a ready-to-use shell.
log_info "Reloading shell... (type 'exit' to return to your previous session)"
exec zsh -l
