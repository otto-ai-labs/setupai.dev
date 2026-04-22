#!/bin/bash
# Step 5: Programming languages — Python, Jupyter, uv, Node.js via nvm.

log_info "Step 5: Installing programming languages and runtimes..."

# Python
# FIX: Check brew list for each version explicitly — the macOS App Store stub
#      satisfies command_exists python3 but is not a usable install.
if ! brew list python@3.12 &>/dev/null; then
    log_info "Installing Python 3.12..."
    brew_install_with_timeout python@3.12 || true
else
    log_success "Python 3.12 already installed"
fi

if ! brew list python@3.11 &>/dev/null; then
    log_info "Installing Python 3.11..."
    brew_install_with_timeout python@3.11 || true
else
    log_success "Python 3.11 already installed"
fi

if command_exists pip3; then
    pip3 install --upgrade pip
    pip3 install virtualenv
fi

# uv — fast Python package and project manager
if ! command_exists uv; then
    log_info "Installing uv (fast Python package manager)..."
    brew_install_with_timeout uv || true
else
    log_success "uv already installed"
fi

# Jupyter — interactive notebooks for AI/data work
log_info "Installing Jupyter (this may take a few minutes)..."
if command_exists pip3; then
    pip3 install jupyter jupyterlab || true
    log_success "Jupyter and JupyterLab installed"
fi

# Node.js via nvm — required for AI CLI tools (Claude Code, Codex)
log_info "Installing Node.js via nvm..."
if [ ! -d "$HOME/.nvm" ]; then
    # FIX: Fetch latest nvm version dynamically.
    # SECURITY NOTE: curl|bash — review https://github.com/nvm-sh/nvm first.
    NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    NVM_VERSION="${NVM_VERSION:-v0.40.1}"   # fallback if GitHub API is unavailable
    log_info "Installing nvm ${NVM_VERSION}..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
        || log_warning "nvm install failed — visit https://github.com/nvm-sh/nvm to install manually"
fi

# FIX: Explicitly source nvm.sh — exporting NVM_DIR alone is not enough.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists node; then
    nvm install --lts
    nvm use --lts
    log_success "Node.js LTS installed via nvm"
else
    log_success "Node.js already installed ($(node --version))"
fi

log_success "Programming languages installed"
echo ""
