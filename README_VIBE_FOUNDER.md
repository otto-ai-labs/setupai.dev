# TheVibeFounder Build Day Stack

> **One command. Ship by end of day.**

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

![TheVibeFounder Build Day Stack](assets/hero.png)

The fastest way to go from a fresh Mac to shipping AI-powered products. No bloat, no noise — just the tools you actually reach for on a build day.

Works on both **Intel** and **Apple Silicon** Macs (M1, M2, M3, M4 and later).

---

## Before You Start

**1. Update macOS** — System Settings → General → Software Update.

**2. Have your Git name and email ready** — same as your GitHub account.

**3. Grab your API keys:**
- [console.anthropic.com](https://console.anthropic.com) → Anthropic key (Claude Code)
- [platform.openai.com](https://platform.openai.com) → OpenAI key (Codex CLI)

**4. Set aside ~20 minutes** — lighter than the full install, but still downloads a few GB.

---

## Run It

Open **Terminal** (`Cmd + Space` → `Terminal`) and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --light
```

Or clone first if you want to review the scripts:

```bash
git clone https://github.com/otto-ai-labs/setupai.dev.git
cd setupai.dev
./setup.sh --light
```

The `--light` flag pre-deselects all the heavy tools. You still get the interactive menus — toggle anything back on if you need it, then press **D** to confirm.

---

## What You Get

### Always installed

| Tool | What it does |
|------|-------------|
| **Homebrew** | Package manager — installs everything else. |
| **Git + SSH key** | Version control, auto-configured and tied to your GitHub email. |
| **Oh My Zsh + Starship** | A fast, clean shell with git-aware prompt. |
| **zsh-autosuggestions** | Suggests commands as you type. |
| **zsh-syntax-highlighting** | Valid commands green, errors red — as you type. |
| **Python 3.12 + uv** | Python and the fastest package manager available. |
| **Node.js LTS** | Installed via nvm. Required for Claude Code and Codex CLI. |
| **bat, eza, fd, ripgrep, fzf** | Modern CLI replacements for cat, ls, find, grep. |
| **jq, yq, htop, tree, wget** | Essential terminal utilities. |

### Pre-selected in menus (on by default)

| Tool | What it does |
|------|-------------|
| **Claude Code** | Anthropic's AI coding CLI. Your main coding tool. |
| **Codex CLI** | OpenAI's coding CLI. |
| **GitHub CLI** | Manage repos, PRs, and issues from the terminal. |
| **Redis** | In-memory store for caching and queues. |
| **SQLite** | Lightweight embedded database for local apps. |
| **Cursor** | AI-native editor — built-in chat, autocomplete, multi-file edits. |
| **Warp** | AI-powered terminal with natural language commands. |
| **iTerm2** | Classic terminal — tabs, split panes, themes. |
| **Obsidian** | Local markdown notes and knowledge base. |
| **Lungo** | Keeps your Mac awake during long installs. |
| **Shottr** | Fast screenshot tool with annotations and OCR. |

### Skipped by default in `--light`

These are off in the menus but you can toggle them back on before confirming:

| Skipped | Why |
|---------|-----|
| Ollama | Large download, GPU-heavy — use Claude/Codex APIs instead |
| Jupyter | Heavyweight, separate Python kernel — not needed for most builds |
| Python 3.11 | 3.12 covers everything |
| PostgreSQL | Overkill for build days — SQLite or Redis handles most cases |
| DuckDB | Analytical DB — niche use case |
| VS Code | Cursor replaces it |
| Raycast | Great app, not essential day one |
| Rectangle / AltTab | Window manager extras — add later if you want |
| LM Studio | GUI for local models — not needed with API access |
| DBeaver / TablePlus | DB GUIs — skip if you're comfortable in the terminal |

---

## After the Script Finishes

**1. Open a new terminal window** (or run `source ~/.zshrc`).

**2. Add your SSH key to GitHub:**
```bash
cat ~/.ssh/id_ed25519.pub
```
Paste it at [github.com/settings/keys](https://github.com/settings/keys).

**3. Set your API keys** — add to `~/.extra` (gitignored, auto-loaded by your shell):
```bash
export ANTHROPIC_API_KEY='sk-ant-...'
export OPENAI_API_KEY='sk-...'
```

**4. Start building:**
```bash
claude       # Claude Code
cursor .     # Open current folder in Cursor
```

**5. Restart your Mac** to apply all system changes.

---

## Troubleshooting

**`claude` not found:**
```bash
source ~/.zshrc
npm install -g @anthropic-ai/claude-code
```

**`node` / `npm` not found:**
```bash
source ~/.zshrc
nvm install --lts && nvm use --lts
```

**`nvm` not found:**
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**A package failed:** Check `~/ai-dev-setup_DATE_TIME.log`, then install manually:
```bash
brew install <package>
npm install -g <package>
```

---

## License

[MIT](LICENSE) — free to use, modify, and share.

---

*Built for founders who ship.*
