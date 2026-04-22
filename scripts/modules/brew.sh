#!/bin/bash
# Steps 1–4: System check, Xcode CLI tools, Homebrew, essential dev tools.

################################################################################
# 1. System Updates
################################################################################
log_info "Step 1: Checking for system updates..."
log_warning "Please ensure you've updated macOS through System Settings first"
echo ""

################################################################################
# 2. Xcode Command Line Tools
################################################################################
log_info "Step 2: Installing Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    log_success "Xcode Command Line Tools already installed"
else
    xcode-select --install
    log_warning "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 0
fi
echo ""

################################################################################
# 3. Homebrew
################################################################################
log_info "Step 3: Installing Homebrew..."
if command -v brew &>/dev/null; then
    log_success "Homebrew already installed at $(which brew)"
    # FIX: Added upgrade after update to keep existing packages current
    brew update && brew upgrade
else
    # SECURITY NOTE: curl|bash runs the remote script with full user permissions.
    # Review https://github.com/Homebrew/install before running on sensitive machines.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$ARCH" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
fi
echo ""

################################################################################
# 4. Essential Development Tools
################################################################################
log_info "Step 4: Installing essential development tools..."

if command_exists git; then
    log_success "Git already installed ($(git --version 2>/dev/null))"
else
    brew_install_with_timeout git
fi

log_info "Installing modern shell tools..."
if ! command_exists zsh; then
    brew_install_with_timeout zsh
else
    log_success "zsh already installed"
fi

if ! brew list zsh-completions &>/dev/null; then
    brew_install_with_timeout zsh-completions
else
    log_success "zsh-completions already installed"
fi

if ! command_exists starship; then
    brew_install_with_timeout starship
else
    log_success "starship already installed"
fi

log_info "Installing modern CLI utilities..."
declare -a cli_tools=("bat" "eza" "fd" "ripgrep" "fzf" "jq" "yq" "htop" "tree" "wget" "curl")

for tool in "${cli_tools[@]}"; do
    if ! command_exists "$tool"; then
        brew_install_with_timeout "$tool" || true
    else
        log_success "$tool already installed"
    fi
done

log_success "Essential development tools installed"
echo ""
