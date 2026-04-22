#!/bin/bash
# Step 6: AI development tools — installs only what the user selected.

if [[ "$SKIP_AI_TOOLS" == true ]]; then
    log_info "Step 6: Skipping AI tools (--skip-ai-tools flag)"
    echo ""
    return 0
fi

log_info "Step 6: Installing AI development tools..."

# Ensure nvm and npm are available in this session before running npm installs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command_exists npm; then
    log_warning "npm not found — skipping npm-based AI tools (Claude Code, Codex)"
    log_warning "Run 'source ~/.zshrc' then re-run this script to install them"
fi

# Helper: should we install this tool?
# In MINIMAL/--yes mode or when no SEL_AI set, fall back to installing everything.
_ai_selected() {
    local key="$1"
    # If SEL_AI is unset (standalone run or --yes), install all
    if [[ -z "${SEL_AI+x}" ]]; then return 0; fi
    array_contains SEL_AI "$key"
}

# Ollama — run large language models locally
if _ai_selected ollama; then
    if command_exists ollama; then
        log_success "Ollama already installed"
    else
        log_info "Installing Ollama (local LLM runner)..."
        brew_install_with_timeout ollama || true
    fi
fi

# Claude Code — Anthropic's official AI coding CLI
if _ai_selected claude && command_exists npm; then
    if command_exists claude; then
        log_success "Claude Code already installed ($(claude --version 2>/dev/null || echo 'ok'))"
    else
        log_info "Installing Claude Code (Anthropic AI coding CLI)..."
        npm install -g @anthropic-ai/claude-code || log_warning "Claude Code install failed — run: npm install -g @anthropic-ai/claude-code"
    fi
fi

# OpenAI Codex CLI
if _ai_selected codex && command_exists npm; then
    if command_exists codex; then
        log_success "OpenAI Codex CLI already installed"
    else
        log_info "Installing OpenAI Codex CLI..."
        npm install -g @openai/codex || log_warning "Codex CLI install failed — run: npm install -g @openai/codex"
    fi
fi

# AWS CLI — useful for AI services (Bedrock, SageMaker)
if _ai_selected awscli; then
    if command_exists aws; then
        log_success "AWS CLI already installed"
    else
        brew_install_with_timeout awscli || true
    fi
fi

# Terraform — infrastructure as code
if _ai_selected terraform; then
    if command_exists terraform; then
        log_success "Terraform already installed"
    else
        brew tap hashicorp/tap || true
        brew_install_with_timeout hashicorp/tap/terraform || true
    fi
fi

# GitHub CLI — manage repos, PRs, issues, and Actions from the terminal
if _ai_selected gh; then
    if command_exists gh; then
        log_success "GitHub CLI already installed ($(gh --version 2>/dev/null | head -1))"
    else
        brew_install_with_timeout gh || true
    fi
fi

# ngrok — expose localhost to the internet (webhooks, demos, sharing)
if _ai_selected ngrok; then
    if command_exists ngrok; then
        log_success "ngrok already installed"
    else
        brew_install_with_timeout ngrok/ngrok/ngrok || true
    fi
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
