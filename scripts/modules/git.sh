#!/bin/bash
# Step 10: Git configuration and SSH key generation.
# Expects $git_username and $git_email to be exported by setup.sh.

log_info "Step 10: Configuring Git..."

git config --global user.name "$git_username"
git config --global user.email "$git_email"
git config --global init.defaultBranch main
git config --global core.editor "vim"
git config --global pull.rebase false

# Generate SSH key
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log_info "Generating SSH key for Git..."
    # FIX (optional hardening): Remove -N "" to be prompted for a passphrase,
    #      which is recommended for keys used on shared or high-security machines.
    ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    log_success "SSH key generated at ~/.ssh/id_ed25519.pub"
    log_warning "Add this key to your GitHub/GitLab account:"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    log_success "SSH key already exists"
fi

log_success "Git configured"
echo ""
