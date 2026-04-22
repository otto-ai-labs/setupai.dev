#!/bin/bash
# Step 8: IDEs and editors — VS Code + extensions.

log_info "Step 8: Installing IDEs and editors..."

if [ -d "/Applications/Visual Studio Code.app" ]; then
    log_success "Visual Studio Code already installed"
else
    brew_install_cask_with_timeout visual-studio-code || true
fi

# VS Code extensions — the `code` CLI is only available after opening VS Code once.
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
