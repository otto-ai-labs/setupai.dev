#!/bin/bash
# Step 9: Productivity apps — installs only what the user selected.

log_info "Step 9: Installing productivity tools..."

_app_selected() {
    local key="$1"
    if [[ -z "${SEL_APPS+x}" ]]; then return 0; fi
    array_contains SEL_APPS "$key"
}

_cask_install() {
    local key="$1"   # selection key
    local cask="$2"  # brew cask name
    local label="$3" # display name
    if _app_selected "$key"; then
        if brew list --cask "$cask" &>/dev/null; then
            log_success "$label already installed"
        else
            brew_install_cask_with_timeout "$cask" || true
        fi
    fi
}

# ── Terminal ──────────────────────────────────────────────────────────────────
_cask_install iterm2    iterm2   "iTerm2"
_cask_install warp      warp     "Warp"

# ── Launcher & productivity ───────────────────────────────────────────────────
_cask_install raycast   raycast  "Raycast"
_cask_install rectangle rectangle "Rectangle"
_cask_install alt-tab   alt-tab  "AltTab"

# ── Notes & knowledge ─────────────────────────────────────────────────────────
_cask_install obsidian  obsidian "Obsidian"

# ── AI Tools (GUI) ────────────────────────────────────────────────────────────
_cask_install lmstudio  lm-studio "LM Studio"

# ── Database GUI ──────────────────────────────────────────────────────────────
_cask_install dbeaver   dbeaver-community "DBeaver"
_cask_install tableplus tableplus         "TablePlus"

# ── Mac utilities ─────────────────────────────────────────────────────────────
_cask_install bartender bartender "Bartender"
_cask_install lungo     lungo     "Lungo"
_cask_install shottr    shottr    "Shottr"

log_success "Productivity tools installed"
echo ""
