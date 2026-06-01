#!/usr/bin/env bash
# paperclip-bedrock-setup.sh — Install Paperclip locally and wire it to AWS Bedrock
#   Auth: ANTHROPIC_BEDROCK_BASE_URL token (no static AWS keys required)

set -euo pipefail

BACKUP_DIR="$HOME/.claude/provider-backups"
PAPERCLIP_DIR="${PAPERCLIP_DIR:-$HOME/paperclip}"
ZSHENV="$HOME/.zshenv"
SAVED_BASE_URL="$BACKUP_DIR/paperclip_bedrock_base_url"
SAVED_REGION="$BACKUP_DIR/paperclip_bedrock_region"
SAVED_DB_URL="$BACKUP_DIR/paperclip_db_url"

mkdir -p "$BACKUP_DIR"

# ── helpers ───────────────────────────────────────────────────────────────────

info()    { printf '  \033[34m→\033[0m %s\n' "$*"; }
success() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()    { printf '  \033[33m!\033[0m %s\n' "$*"; }
error()   { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" &>/dev/null || error "'$1' is required but not installed."
}

strip_paperclip_vars() {
  if [[ -f "$ZSHENV" ]]; then
    sed -i.bak \
      -e '/ANTHROPIC_BEDROCK_BASE_URL/d' \
      -e '/PAPERCLIP_AWS_REGION/d' \
      -e '/# ── paperclip-bedrock/d' \
      "$ZSHENV"
    sed -i.bak '/^[[:space:]]*$/d' "$ZSHENV"
  fi
}

append_env_block() {
  local block="$1"
  touch "$ZSHENV"
  printf '\n# ── paperclip-bedrock ──\n%s\n' "$block" >> "$ZSHENV"
}

reload_env() {
  # shellcheck disable=SC1090
  source "$ZSHENV"
  success "Environment reloaded from $ZSHENV"
}

# ── step 1: check deps ────────────────────────────────────────────────────────

check_deps() {
  echo ""
  echo "Checking dependencies..."
  require_cmd node
  require_cmd git

  local node_major
  node_major="$(node -e 'process.stdout.write(process.versions.node.split(".")[0])')"
  (( node_major >= 20 )) || error "Node.js 20+ required (found v${node_major})."
  success "Node.js v$(node --version | tr -d v) OK"

  if ! command -v pnpm &>/dev/null; then
    warn "pnpm not found — installing globally..."
    npm install -g pnpm@latest
  fi
  success "pnpm $(pnpm --version) OK"
}

# ── step 2: clone / update paperclip ─────────────────────────────────────────

setup_paperclip_repo() {
  echo ""
  echo "Setting up Paperclip repo at $PAPERCLIP_DIR..."

  if [[ -d "$PAPERCLIP_DIR/.git" ]]; then
    info "Repo already exists — pulling latest..."
    git -C "$PAPERCLIP_DIR" pull --ff-only
    success "Paperclip up to date."
  else
    info "Cloning paperclipai/paperclip..."
    git clone https://github.com/paperclipai/paperclip.git "$PAPERCLIP_DIR"
    success "Cloned to $PAPERCLIP_DIR"
  fi

  info "Installing dependencies (pnpm install)..."
  pnpm --dir "$PAPERCLIP_DIR" install --frozen-lockfile
  success "Dependencies installed."
}

# ── step 3: collect bedrock token ─────────────────────────────────────────────

collect_bedrock_token() {
  echo ""
  echo "Configuring AWS Bedrock (ANTHROPIC_BEDROCK_BASE_URL)..."

  local base_url region

  if [[ -f "$SAVED_BASE_URL" && -f "$SAVED_REGION" ]]; then
    base_url="$(cat "$SAVED_BASE_URL")"
    region="$(cat "$SAVED_REGION")"
    info "Using saved Bedrock base URL: ${base_url:0:40}..."
    info "Using saved region: $region"

    read -rp "  Re-enter credentials? [y/N]: " reenter
    if [[ "${reenter,,}" == "y" ]]; then
      rm -f "$SAVED_BASE_URL" "$SAVED_REGION"
      collect_bedrock_token
      return
    fi
  else
    echo ""
    echo "  The Bedrock base URL is the endpoint your org's Bedrock proxy exposes."
    echo "  Format: https://<host>/bedrock  or  https://bedrock.us-east-1.amazonaws.com"
    echo ""
    read -rp  "  ANTHROPIC_BEDROCK_BASE_URL: " base_url
    [[ -n "$base_url" ]] || error "Base URL cannot be empty."

    read -rp  "  AWS Region [us-east-1]: " region
    region="${region:-us-east-1}"

    printf '%s' "$base_url" > "$SAVED_BASE_URL"
    printf '%s' "$region"   > "$SAVED_REGION"
    chmod 600 "$SAVED_BASE_URL"
    success "Credentials saved to $BACKUP_DIR"
  fi

  strip_paperclip_vars
  append_env_block "export ANTHROPIC_BEDROCK_BASE_URL='$base_url'
export PAPERCLIP_AWS_REGION='$region'"
  reload_env
}

# ── step 4: write paperclip .env ──────────────────────────────────────────────

write_paperclip_env() {
  echo ""
  echo "Writing Paperclip .env..."

  local env_file="$PAPERCLIP_DIR/.env"
  local db_url auth_secret

  # Database URL
  if [[ -f "$SAVED_DB_URL" ]]; then
    db_url="$(cat "$SAVED_DB_URL")"
    info "Using saved DB URL: ${db_url:0:40}..."
  else
    echo ""
    echo "  Paperclip needs a PostgreSQL database."
    echo "  Default uses the embedded local DB (press Enter to accept)."
    read -rp "  DATABASE_URL [postgres://paperclip:paperclip@localhost:5432/paperclip]: " db_url
    db_url="${db_url:-postgres://paperclip:paperclip@localhost:5432/paperclip}"
    printf '%s' "$db_url" > "$SAVED_DB_URL"
  fi

  # Auth secret — generate one if not already in .env
  if [[ -f "$env_file" ]] && grep -q 'BETTER_AUTH_SECRET' "$env_file"; then
    auth_secret="$(grep 'BETTER_AUTH_SECRET' "$env_file" | cut -d= -f2)"
    info "Keeping existing BETTER_AUTH_SECRET."
  else
    auth_secret="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40)"
    info "Generated new BETTER_AUTH_SECRET."
  fi

  cat > "$env_file" <<ENV
DATABASE_URL=${db_url}
PORT=3100
SERVE_UI=false
BETTER_AUTH_SECRET=${auth_secret}

# Bedrock provider — set via shell env (see ~/.zshenv)
# ANTHROPIC_BEDROCK_BASE_URL is exported from ~/.zshenv by paperclip-bedrock-setup.sh

# Disable telemetry (optional)
# PAPERCLIP_TELEMETRY_DISABLED=1
ENV

  chmod 600 "$env_file"
  success "Wrote $env_file"
}

# ── step 5: status / summary ──────────────────────────────────────────────────

show_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Paperclip + Bedrock setup complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Paperclip dir : $PAPERCLIP_DIR"
  echo "  Bedrock URL   : ${ANTHROPIC_BEDROCK_BASE_URL:-<not set — reload shell>}"
  echo "  AWS Region    : ${PAPERCLIP_AWS_REGION:-<not set — reload shell>}"
  echo ""
  echo "  Next steps:"
  echo ""
  echo "  1) Reload your shell (or open a new terminal):"
  echo "       source ~/.zshenv"
  echo ""
  echo "  2) Start Paperclip:"
  echo "       cd $PAPERCLIP_DIR"
  echo "       pnpm dev"
  echo ""
  echo "  3) Open the UI:"
  echo "       http://localhost:3100"
  echo ""
  echo "  4) Add a Claude Code agent in the Paperclip UI."
  echo "     Paperclip's claude-local adapter reads ANTHROPIC_BEDROCK_BASE_URL"
  echo "     from your environment and automatically uses Bedrock model IDs."
  echo ""
  echo "  To update your Bedrock token later:"
  echo "       $(basename "$0") update-token"
  echo ""
}

# ── update saved token ────────────────────────────────────────────────────────

update_token() {
  rm -f "$SAVED_BASE_URL" "$SAVED_REGION"
  collect_bedrock_token
  success "Bedrock token updated."
}

# ── show current status ───────────────────────────────────────────────────────

show_status() {
  echo ""
  echo "Paperclip Bedrock status:"
  echo ""
  local url="${ANTHROPIC_BEDROCK_BASE_URL:-}"
  local region="${PAPERCLIP_AWS_REGION:-}"
  [[ -n "$url" ]]    && echo "  ANTHROPIC_BEDROCK_BASE_URL : ${url:0:40}..." || echo "  ANTHROPIC_BEDROCK_BASE_URL : (not set)"
  [[ -n "$region" ]] && echo "  PAPERCLIP_AWS_REGION       : $region"         || echo "  PAPERCLIP_AWS_REGION       : (not set)"
  echo ""
  [[ -d "$PAPERCLIP_DIR/.git" ]] && echo "  Paperclip dir : $PAPERCLIP_DIR (installed)" \
                                  || echo "  Paperclip dir : $PAPERCLIP_DIR (not found — run: $(basename "$0") install)"
}

# ── usage ─────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  install        Clone Paperclip, install deps, configure Bedrock token, write .env
  update-token   Re-enter your ANTHROPIC_BEDROCK_BASE_URL
  status         Show current Bedrock configuration

Examples:
  $(basename "$0") install
  $(basename "$0") update-token
  $(basename "$0") status

Environment:
  PAPERCLIP_DIR   Override install directory (default: ~/paperclip)
EOF
}

# ── main ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
  install)
    check_deps
    setup_paperclip_repo
    collect_bedrock_token
    write_paperclip_env
    show_summary
    ;;
  update-token)
    update_token
    ;;
  status)
    show_status
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage
    exit 1
    ;;
esac
