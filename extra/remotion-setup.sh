#!/usr/bin/env bash
# remotion-setup.sh — Scaffold a new Remotion project locally
#   Creates a React-based programmatic video project using create-video@latest

set -euo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────

info()    { printf '  \033[34m→\033[0m %s\n' "$*"; }
success() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
error()   { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }
ask()     { read -rp "  $*" REPLY; echo "$REPLY"; }

require_cmd() {
  command -v "$1" &>/dev/null || error "'$1' is required but not installed. $2"
}

# ── templates ─────────────────────────────────────────────────────────────────

list_templates() {
  cat <<EOF
  Available templates:
    blank          Minimal starter — one composition, no extras
    hello-world    Default starter with example animations  (recommended)
    still          Single-frame image export
    tiktok         Vertical 9:16 video
    overlay        Video overlay / watermark
    audiogram      Podcast waveform visualizer
    three          React Three Fiber (3D)
    skia           React Native Skia (GPU drawing)
    next-app       Next.js App Router + Remotion
    next-pages     Next.js Pages Router + Remotion
    react-router   React Router v7 + Remotion
EOF
}

# ── step 1: check deps ────────────────────────────────────────────────────────

check_deps() {
  echo ""
  echo "Checking dependencies..."

  require_cmd node "Install from https://nodejs.org (v16+ required)."
  local node_major
  node_major="$(node -e 'process.stdout.write(process.versions.node.split(".")[0])')"
  (( node_major >= 16 )) || error "Node.js 16+ required (found v${node_major})."
  success "Node.js v$(node --version | tr -d v) OK"

  require_cmd npm "Install from https://nodejs.org."
  success "npm $(npm --version) OK"

  info "Remotion bundles its own ffmpeg and Chromium — no system installs needed."
}

# ── step 2: scaffold project ──────────────────────────────────────────────────

scaffold_project() {
  echo ""

  # Project directory
  local project_dir
  project_dir="$(ask "Project directory [my-video]: ")"
  project_dir="${project_dir:-my-video}"
  [[ -e "$project_dir" ]] && error "'$project_dir' already exists. Choose a different name."

  # Template
  echo ""
  list_templates
  echo ""
  local template
  template="$(ask "Template [hello-world]: ")"
  template="${template:-hello-world}"

  # Package manager
  echo ""
  echo "  Package manager:"
  echo "    1) npm  (default)"
  echo "    2) pnpm"
  echo "    3) bun"
  echo "    4) yarn"
  local pm_choice pm
  pm_choice="$(ask "Choose [1]: ")"
  case "${pm_choice:-1}" in
    2) pm="pnpm" ;;
    3) pm="bun"  ;;
    4) pm="yarn" ;;
    *) pm="npm"  ;;
  esac

  echo ""
  info "Scaffolding '$project_dir' with template '$template' using $pm..."

  npx create-video@latest \
    --yes \
    --template "$template" \
    --package-manager "$pm" \
    "$project_dir"

  success "Project created at ./$project_dir"

  PROJECT_DIR="$project_dir"
  PM="$pm"
}

# ── step 3: summary ───────────────────────────────────────────────────────────

show_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Remotion project ready"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Project         : ./$PROJECT_DIR"
  echo "  Package manager : $PM"
  echo ""
  echo "  ── Start Remotion Studio ──────────────"
  echo "  cd $PROJECT_DIR"
  case "$PM" in
    pnpm) echo "  pnpm dev" ;;
    bun)  echo "  bun run dev" ;;
    yarn) echo "  yarn dev" ;;
    *)    echo "  npm run dev" ;;
  esac
  echo "  → Opens at http://localhost:3000"
  echo ""
  echo "  ── Render to file ─────────────────────"
  echo "  npx remotion render <CompositionId>"
  echo "  # Output: ./$PROJECT_DIR/out/<CompositionId>.mp4"
  echo ""
  echo "  ── Export a still ─────────────────────"
  echo "  npx remotion still <CompositionId>"
  echo "  # Output: ./$PROJECT_DIR/out/<CompositionId>.png"
  echo ""
  echo "  ── Docs ────────────────────────────────"
  echo "  Guides  : https://www.remotion.dev/docs"
  echo "  API     : https://www.remotion.dev/api"
  echo "  Discord : https://remotion.dev/discord"
  echo ""
}

# ── usage ─────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  new          Scaffold a new Remotion project (interactive)
  templates    List available project templates

Examples:
  $(basename "$0") new
  $(basename "$0") templates
EOF
}

# ── main ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
  new)
    check_deps
    scaffold_project
    show_summary
    ;;
  templates)
    list_templates
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
