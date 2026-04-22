#!/bin/bash
# Step 11: Shell configuration — Oh My Zsh, plugins, and .zshrc setup.
# Expects $ARCH_NAME and $BREW_PREFIX to be exported by setup.sh.

log_info "Step 11: Configuring shell..."

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_success "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
        || log_warning "zsh-autosuggestions install failed — skipping"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
        || log_warning "zsh-syntax-highlighting install failed — skipping"
fi

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backed up existing .zshrc"
fi

# Update plugins line
if grep -q "^plugins=" "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=.*/plugins=(git python zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
else
    echo 'plugins=(git python zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
fi

# Patch existing installs — add python/pip aliases if missing
if grep -q "# === ai-dev-setup Config ===" "$HOME/.zshrc" && ! grep -q "alias python=" "$HOME/.zshrc"; then
    sed -i '' "s/# Jupyter aliases/# Python aliases — Homebrew installs python3, not python\nalias python='python3'\nalias pip='pip3'\n\n# Jupyter aliases/" "$HOME/.zshrc"
    log_success "Added python/pip aliases to existing ~/.zshrc"
fi

# Append config block (idempotent — skipped if marker already present)
if ! grep -q "# === ai-dev-setup Config ===" "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << EOF

# === ai-dev-setup Config ===

# NVM configuration
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"

# Homebrew ($ARCH_NAME)
eval "\$($BREW_PREFIX/bin/brew shellenv)"

# uv — Python package manager
export PATH="\$HOME/.local/bin:\$PATH"

# Starship prompt
# Run 'starship preset plain-text > ~/.config/starship.toml'
# or visit https://starship.rs/presets/ to customise your prompt theme.
command -v starship &>/dev/null && eval "\$(starship init zsh)"

# Python aliases — Homebrew installs python3, not python
alias python='python3'
alias pip='pip3'

# Jupyter aliases
alias jl='jupyter lab'
alias jn='jupyter notebook'

# Aliases - DISABLED to allow both traditional and modern tools to coexist
# Uncomment any aliases you want to use:
# alias ls='eza'
# alias ll='eza -la'
# alias la='eza -la'
# alias cat='bat'
# alias find='fd'
# alias grep='rg'
#
# Modern CLI tools installed and available by their actual names:
# - eza (modern ls with colors, icons, git status)
# - bat (cat with syntax highlighting)
# - fd (faster, simpler find)
# - rg/ripgrep (faster grep)
# - fzf (fuzzy finder)

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Personal overrides — API keys, custom aliases, private config
# Create ~/.extra and put anything you don't want in version control there
[ -f ~/.extra ] && source ~/.extra

# === End ai-dev-setup Config ===
EOF
    log_success "Custom shell configurations added"
else
    log_info "Custom shell configurations already present, skipping"
fi

log_success "Shell configured"
echo ""
