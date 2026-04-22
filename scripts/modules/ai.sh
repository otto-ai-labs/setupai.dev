#!/bin/bash
# Step 6: AI development tools — Ollama, Claude Code, Codex CLI, AWS CLI, Terraform.

if [[ "$SKIP_AI_TOOLS" == true ]]; then
    log_info "Step 6: Skipping AI tools (--skip-ai-tools flag)"
    echo ""
    return 0
fi

log_info "Step 6: Installing AI development tools..."

# Ollama — run large language models locally
if command_exists ollama; then
    log_success "Ollama already installed"
else
    log_info "Installing Ollama (local LLM runner)..."
    brew_install_with_timeout ollama || true
fi

# Claude Code — Anthropic's official AI coding CLI
# npm must be available (installed via nvm in languages.sh)
if command_exists claude; then
    log_success "Claude Code already installed"
else
    log_info "Installing Claude Code (Anthropic AI coding CLI)..."
    npm install -g @anthropic-ai/claude-code || true
fi

# OpenAI Codex CLI
if command_exists codex; then
    log_success "OpenAI Codex CLI already installed"
else
    log_info "Installing OpenAI Codex CLI..."
    npm install -g @openai/codex || true
fi

# AWS CLI — useful for AI services (Bedrock, SageMaker)
if command_exists aws; then
    log_success "AWS CLI already installed"
else
    brew_install_with_timeout awscli || true
fi

# Terraform — infrastructure as code
if command_exists terraform; then
    log_success "Terraform already installed"
else
    brew tap hashicorp/tap || true
    brew_install_with_timeout hashicorp/tap/terraform || true
fi

# Docker — note only, do not auto-install (requires GUI setup)
if [ -d "/Applications/Docker.app" ]; then
    log_success "Docker already installed"
else
    log_info "Docker: download and install from https://www.docker.com/products/docker-desktop/"
    log_warning "Docker requires manual installation — visit docker.com to download Docker Desktop"
fi

log_success "AI development tools installed"
echo ""
