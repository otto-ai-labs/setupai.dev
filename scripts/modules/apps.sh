#!/bin/bash
# Step 9: Productivity apps — iTerm2, Rectangle.

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
