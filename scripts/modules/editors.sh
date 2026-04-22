#!/bin/bash
# Step 8: IDEs and editors — installs only what the user selected.

log_info "Step 8: Installing IDEs and editors..."

_editor_selected() {
    local key="$1"
    if [[ -z "${SEL_EDITORS+x}" ]]; then return 0; fi
    array_contains SEL_EDITORS "$key"
}

# VS Code
if _editor_selected vscode; then
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        log_success "Visual Studio Code already installed"
    else
        brew_install_cask_with_timeout visual-studio-code || true
    fi

    # VS Code extensions — try known CLI paths since `code` isn't in PATH
    # until the user opens VS Code once manually.
    VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if command_exists code; then
        CODE_CMD="code"
    elif [ -f "$VSCODE_CLI" ]; then
        CODE_CMD="$VSCODE_CLI"
    else
        CODE_CMD=""
    fi

    if [[ -n "$CODE_CMD" ]]; then
        log_info "Installing VS Code extensions..."
        "$CODE_CMD" --install-extension ms-python.python || true
        "$CODE_CMD" --install-extension ms-toolsai.jupyter || true
        "$CODE_CMD" --install-extension anthropic.claude || true
        "$CODE_CMD" --install-extension github.copilot || true
        log_success "VS Code extensions installed"
    else
        log_warning "VS Code CLI not yet available — extensions will be installed on first launch"
        log_info "Or install manually after opening VS Code:"
        log_info "  code --install-extension ms-python.python"
        log_info "  code --install-extension ms-toolsai.jupyter"
        log_info "  code --install-extension anthropic.claude"
        log_info "  code --install-extension github.copilot"
    fi
fi

# Cursor — AI-native VS Code fork
if _editor_selected cursor; then
    if [ -d "/Applications/Cursor.app" ]; then
        log_success "Cursor already installed"
    else
        brew_install_cask_with_timeout cursor || true
    fi
fi

log_success "IDEs and editors installed"
echo ""
