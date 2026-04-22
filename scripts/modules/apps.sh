#!/bin/bash
# Step 9: Productivity apps — terminal, launchers, utilities, and GUI tools.

log_info "Step 9: Installing productivity tools..."

# ── Terminal ──────────────────────────────────────────────────────────────────
# iTerm2 — classic terminal emulator
if brew list --cask iterm2 &>/dev/null; then
    log_success "iTerm2 already installed"
else
    brew_install_cask_with_timeout iterm2 || true
fi

# Warp — AI-powered terminal (autocomplete, natural language commands)
if brew list --cask warp &>/dev/null; then
    log_success "Warp already installed"
else
    brew_install_cask_with_timeout warp || true
fi

# ── Launcher & productivity ───────────────────────────────────────────────────
# Raycast — Spotlight replacement with AI, clipboard history, and extensions
if brew list --cask raycast &>/dev/null; then
    log_success "Raycast already installed"
else
    brew_install_cask_with_timeout raycast || true
fi

# Rectangle — window manager (keyboard shortcuts to snap/tile windows)
if brew list --cask rectangle &>/dev/null; then
    log_success "Rectangle already installed"
else
    brew_install_cask_with_timeout rectangle || true
fi

# AltTab — Windows-style app switcher with live window previews
if brew list --cask alt-tab &>/dev/null; then
    log_success "AltTab already installed"
else
    brew_install_cask_with_timeout alt-tab || true
fi

# ── Notes & knowledge ─────────────────────────────────────────────────────────
# Obsidian — local-first markdown notes / knowledge base
if brew list --cask obsidian &>/dev/null; then
    log_success "Obsidian already installed"
else
    brew_install_cask_with_timeout obsidian || true
fi

# ── AI Tools (GUI) ────────────────────────────────────────────────────────────
# LM Studio — GUI app to discover, download, and run local AI models
if brew list --cask lm-studio &>/dev/null; then
    log_success "LM Studio already installed"
else
    brew_install_cask_with_timeout lm-studio || true
fi

# ── Database GUI ──────────────────────────────────────────────────────────────
# DBeaver — universal database GUI (PostgreSQL, SQLite, Redis, and more)
if brew list --cask dbeaver-community &>/dev/null; then
    log_success "DBeaver already installed"
else
    brew_install_cask_with_timeout dbeaver-community || true
fi

# TablePlus — fast, modern database GUI with a native Mac feel
if brew list --cask tableplus &>/dev/null; then
    log_success "TablePlus already installed"
else
    brew_install_cask_with_timeout tableplus || true
fi

# ── Mac utilities ─────────────────────────────────────────────────────────────
# Bartender — organise and hide menu bar icons
if brew list --cask bartender &>/dev/null; then
    log_success "Bartender already installed"
else
    brew_install_cask_with_timeout bartender || true
fi

# Lungo — keep your Mac awake (prevents sleep during long installs / downloads)
if brew list --cask lungo &>/dev/null; then
    log_success "Lungo already installed"
else
    brew_install_cask_with_timeout lungo || true
fi

# Shottr — fast, lightweight screenshot tool with annotations and OCR
if brew list --cask shottr &>/dev/null; then
    log_success "Shottr already installed"
else
    brew_install_cask_with_timeout shottr || true
fi

log_success "Productivity tools installed"
echo ""
