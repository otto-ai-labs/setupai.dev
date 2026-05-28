# TheVibeFounder Build Day Stack

> **One command. Ship by end of day.**

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

![TheVibeFounder Build Day Stack](assets/hero.png)

The fastest way to go from a fresh Mac to shipping AI-powered products. Built for founders who move fast — no fluff, no bloat, just the tools you actually need on a build day.

Works on both **Intel** and **Apple Silicon** Macs (M1, M2, M3, M4 and later).

---

## Table of Contents

- [Before You Start](#before-you-start)
- [Quick Start](#quick-start)
- [The Light Stack](#the-light-stack)
- [What Gets Installed](#what-gets-installed)
- [Installation Options](#installation-options)
- [After the Script Finishes](#after-the-script-finishes)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)

---

## Before You Start

Five minutes now saves an hour later.

**1. Update macOS**
System Settings → General → Software Update. Install everything pending.

**2. Have your Git details ready**
Your name and email — use the same ones as your GitHub account.

**3. Grab your API keys**
You'll need at least one of these to start building:
- [console.anthropic.com](https://console.anthropic.com) → Anthropic API key (for Claude Code)
- [platform.openai.com](https://platform.openai.com) → OpenAI API key (for Codex CLI)

**4. Stable internet + 30–60 minutes**
The script downloads several gigabytes. Walk away after it starts — just stay nearby in case a password prompt appears.

---

## Quick Start

Open **Terminal** (`Cmd + Space` → type `Terminal` → Enter) and run one of these.

### Run directly

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh)
```

### Download first, then run

```bash
git clone https://github.com/otto-ai-labs/setupai.dev.git
cd setupai.dev
./setup.sh
```

The script shows an interactive menu before installing anything. Use **↑/↓** to move, **Space** to toggle, **D** to confirm, **A** to select all, **N** to deselect all.

---

## The Light Stack

Want a faster, leaner install? Use `--light`.

It skips the heavy tools — no Ollama, no Jupyter, no PostgreSQL, no DuckDB, no VS Code, no GUI database browsers — and pre-deselects everything you don't need on a typical build day. You still get the full interactive menus so you can add anything back.

```bash
# Clone and run light
./setup.sh --light

# Or via curl
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --light
```

**What the light stack gives you:**

| Category | Included |
|----------|---------|
| Core CLI tools | Everything — git, ripgrep, fzf, bat, eza, jq, etc. |
| Python 3.12 + uv | Yes |
| Node.js (via nvm) | Yes |
| Claude Code | Yes |
| Codex CLI | Yes |
| GitHub CLI | Yes |
| Redis, SQLite | Yes |
| Cursor (AI editor) | Yes |
| Warp terminal | Yes |
| Obsidian | Yes |
| Lungo, Shottr | Yes |

**What it skips by default:**

Ollama · AWS CLI · PostgreSQL · DuckDB · Jupyter · VS Code · Raycast · Rectangle · AltTab · LM Studio · DBeaver · TablePlus

You can still toggle any of these back on in the menus — `--light` only changes the defaults.

---

## What Gets Installed

Here is every tool the script can install. Nothing is hidden.

---

### Essential Tools
*Always installed. The foundation everything else builds on.*

| Tool | What it does |
|------|-------------|
| **Homebrew** | Package manager for macOS — installs almost everything else. |
| **Git** | Version control — track changes, branch, collaborate. |
| **SSH Key** | Auto-generated key tied to your Git email. Add it to GitHub once. |
| **Starship** | Fast terminal prompt — shows your Git branch, Python env, and more. |
| **Oh My Zsh** | Shell framework with plugins, themes, and autocompletion. |
| **zsh-autosuggestions** | Suggests commands as you type based on history. |
| **zsh-syntax-highlighting** | Valid commands in green, errors in red — as you type. |
| **bat** | `cat` with syntax highlighting and line numbers. |
| **eza** | Modern `ls` with colours, icons, and Git status. |
| **fd** | Faster, friendlier alternative to `find`. |
| **ripgrep** | Extremely fast alternative to `grep`. |
| **fzf** | Fuzzy command-line finder — search files, history, and more. |
| **jq** | Parse and query JSON from the terminal. |
| **yq** | Parse and query YAML from the terminal. |
| **htop** | Interactive process viewer — better than `top`. |
| **tree** | Display directory structure as a tree. |
| **wget / curl** | Download files from the internet via the terminal. |

---

### Languages & Runtimes

| Tool | Notes |
|------|-------|
| **Python 3.12 & 3.11** | Both installed via Homebrew. |
| **uv** | Lightning-fast Python package and project manager. Replaces pip and poetry. |
| **pip + virtualenv** | Upgraded and installed automatically. |
| **Jupyter / JupyterLab** | Interactive notebooks for AI experimentation. *(Skipped in `--light` mode.)* |
| **Node.js LTS** | Installed via nvm. Required for Claude Code and Codex CLI. |
| **nvm** | Node Version Manager — switch between Node versions easily. |

**Shell aliases added to `~/.zshrc`:**
```bash
jl   # → jupyter lab
jn   # → jupyter notebook
```

---

### AI Tools
*Select during setup. Can be skipped with `--skip-ai-tools`.*

| Tool | What it does |
|------|-------------|
| **Claude Code** | Anthropic's official AI coding CLI. The fastest way to build with Claude. Requires `ANTHROPIC_API_KEY`. |
| **Codex CLI** | OpenAI's coding CLI. Requires `OPENAI_API_KEY`. |
| **Ollama** | Run LLMs locally — Llama, Mistral, Gemma, and more. No API key needed. *(Off by default in `--light`.)* |
| **GitHub CLI (`gh`)** | Manage repos, PRs, issues, and Actions from the terminal. |
| **AWS CLI** | Access Bedrock, SageMaker, and other AWS AI services. *(Off by default in `--light`.)* |
| **Terraform** | Infrastructure as code for AI deployments. *(Off by default.)* |
| **ngrok** | Expose localhost to the internet — great for webhooks and demos. *(Off by default.)* |

> **Docker** is not auto-installed — it requires a manual GUI setup. Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/).

---

### Databases
*Select during setup. Can be skipped with `--skip-databases`.*

| Database | Use case |
|----------|---------|
| **Redis** | In-memory cache, queues, and session store. |
| **SQLite** | Lightweight embedded database — ideal for local AI apps and prototypes. |
| **PostgreSQL 15** | The most popular open-source relational database. *(Off by default in `--light`.)* |
| **DuckDB** | Fast in-process analytical DB — SQL on files and dataframes, no server needed. *(Off by default in `--light`.)* |

> Databases are installed but **not auto-started**. Run `brew services start redis` only when you need them.

---

### Editors
*Select during setup.*

| Tool | What it does |
|------|-------------|
| **Cursor** | AI-native code editor with built-in chat, autocomplete, and multi-file editing. The default for vibe coders. |
| **VS Code** | The most popular free editor — installed with Python, Jupyter, Claude, and GitHub Copilot extensions. *(Off by default in `--light`.)* |

---

### Productivity Apps
*Select during setup.*

| Tool | What it does |
|------|-------------|
| **Warp** | AI-powered terminal — natural language commands, autocomplete, and a modern UI. |
| **iTerm2** | Classic terminal emulator — tabs, split panes, themes, and scripting. |
| **Obsidian** | Local-first markdown notes and knowledge base — great for personal docs and context management. |
| **Lungo** | Keep your Mac awake during long installs or builds. |
| **Shottr** | Lightweight screenshot tool with annotations, measurement, and OCR. |
| **Bartender** | Organise and hide cluttered menu bar icons. *(Off by default.)* |
| **Raycast** | Spotlight replacement with AI, clipboard history, and window management. *(Off by default in `--light`.)* |
| **Rectangle** | Snap windows to halves, thirds, and corners with keyboard shortcuts. *(Off by default in `--light`.)* |
| **AltTab** | Windows-style app switcher with live window previews. *(Off by default in `--light`.)* |
| **LM Studio** | GUI app to run local AI models — no terminal knowledge required. *(Off by default in `--light`.)* |
| **DBeaver** | Universal database GUI for Postgres, SQLite, and more. *(Off by default in `--light`.)* |
| **TablePlus** | Fast, native Mac database GUI. *(Off by default.)* |

---

### Web & JavaScript Tools
*Installed by `web.sh`. Can be skipped with `--skip-web`.*

| Tool | What it does |
|------|-------------|
| **pnpm** | Fast, disk-efficient package manager. |
| **TypeScript** | Typed superset of JavaScript — standard for modern projects. |
| **ts-node / tsx** | Run TypeScript files directly without compiling. |
| **ESLint + Prettier** | Lint and format your code automatically. |
| **Biome** | Ultra-fast all-in-one linter and formatter. |
| **Vite** | Lightning-fast build tool and dev server. |
| **Turbo** | High-performance build system for monorepos. |
| **Vercel CLI** | Deploy to Vercel from the terminal. |
| **serve / http-server** | Instantly serve a local folder over HTTP. |
| **nodemon** | Auto-restarts your Node app when files change. |
| **concurrently** | Run multiple npm scripts in parallel. |
| **dotenv-cli** | Load `.env` files when running CLI commands. |
| **Bruno** | Open-source API client — alternative to Postman. |

---

## Installation Options

### Interactive menus

The script presents a checkbox menu for each category before installing anything:

```
  AI Tools  —  Tools for building and running AI applications
  ────────────────────────────────────────────────────────────
▶ [x] Claude Code           Anthropic AI coding CLI
  [x] Codex CLI             OpenAI coding CLI
  [ ] Ollama                Run LLMs locally (off in --light)
  [ ] AWS CLI               Access Bedrock, SageMaker and more
  [ ] Terraform             Infrastructure as code
  [x] GitHub CLI            Manage repos, PRs and issues
  [ ] ngrok                 Expose localhost to the internet
  ────────────────────────────────────────────────────────────
  Up/Down: move  Space/Enter: toggle  D: done  A: all  N: none
```

### Flags

```
./setup.sh [OPTIONS]

  --yes, -y          Auto-answer yes to upgrade prompts for already-installed tools
  --light            Lean install — pre-deselects heavy tools (Ollama, Jupyter,
                     PostgreSQL, DuckDB, VS Code, Raycast, Rectangle, AltTab,
                     LM Studio, DBeaver, TablePlus). Menus still shown.
  --minimal          Essentials only — languages + shell. Skips all menus.
  --skip-ai-tools    Skip the AI tools category entirely
  --skip-databases   Skip the databases category entirely
  --skip-web         Skip the web/JS tools entirely
  --help             Show all available options
```

### Common commands

```bash
# Full interactive install
./setup.sh

# Light stack — recommended for a fast build day setup
./setup.sh --light

# Upgrade everything without prompts
./setup.sh --yes

# Bare minimum — languages and shell only
./setup.sh --minimal

# No databases (you run everything in Docker)
./setup.sh --skip-databases

# No AI tools (general dev machine)
./setup.sh --skip-ai-tools
```

### Via curl

```bash
# Full install
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh)

# Light stack
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --light

# Light + auto-upgrade
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --light --yes
```

---

## After the Script Finishes

**1. Restart your terminal**
```bash
source ~/.zshrc
```
Or just close and open a new terminal window.

**2. Add your SSH key to GitHub**
```bash
cat ~/.ssh/id_ed25519.pub
```
Copy the output and add it at [github.com/settings/keys](https://github.com/settings/keys).

**3. Set your API keys**
Add these to `~/.extra` — it's gitignored and loaded automatically by your shell:
```bash
export ANTHROPIC_API_KEY='sk-ant-...'   # console.anthropic.com
export OPENAI_API_KEY='sk-...'          # platform.openai.com
```

**4. Start building with Claude Code**
```bash
claude
```

**5. Open Cursor**
Launch Cursor from your Applications folder. It's your AI-native editor for build days.

**6. Restart your Mac** *(recommended)*
Ensures all system-level changes take effect.

---

## Directory Structure

The script creates a clean folder layout in your home directory:

```
~/Development/
├── projects/          ← Your active product builds
├── learning/          ← Tutorials, experiments, practice code
├── tools/             ← Custom tools you build or install manually
├── scripts/           ← Your automation and utility scripts
└── ai-experiments/    ← AI prototypes, notebooks, model experiments
```

---

## Troubleshooting

**Xcode popup appeared and the script stopped**
Click Install, wait for it to finish, then re-run the script.

**A package failed to install**
The script logs everything to `~/ai-dev-setup_DATE_TIME.log`. Install the failed package manually:
```bash
brew install <package-name>
npm install -g <package-name>
```

**`claude` command not found**
```bash
source ~/.zshrc
npm install -g @anthropic-ai/claude-code
```

**`node` or `npm` not found**
```bash
source ~/.zshrc
nvm install --lts && nvm use --lts
```

**`nvm` command not found**
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
Then reopen your terminal.

**`uv` command not found**
```bash
source ~/.zshrc
brew install uv
```

**`gh` command not found**
```bash
source ~/.zshrc
brew install gh
```

**Python version confusion**
```bash
python3.12 --version
python3.11 --version

# Use a specific version in a project:
uv venv --python 3.12
```

**Git config is blank**
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

---

## Security & Privacy

**Review before you run**
This script — and some tools it installs — use the `curl | bash` pattern. The scripts run with your full user permissions. Review them first:
- [This repo](https://github.com/otto-ai-labs/setupai.dev) — start with `setup.sh` and `brew.sh`
- [Homebrew install script](https://github.com/Homebrew/install)
- [nvm install script](https://github.com/nvm-sh/nvm)
- [Oh My Zsh install script](https://github.com/ohmyzsh/ohmyzsh)

**SSH key has no passphrase by default**
This keeps setup non-interactive. To add a passphrase, open `scripts/modules/git.sh` and remove `-N ""` from the `ssh-keygen` line.

**App quarantine is disabled**
`osx.sh` sets `LSQuarantine = false` — downloaded apps open without the "Are you sure?" prompt. Remove that line from `osx.sh` if you prefer to keep it enabled.

**Keep credentials in `~/.extra`**
Your shell auto-loads `~/.extra` if it exists. Put API keys there — never in `~/.zshrc`.

**Recommended extras**
- FileVault: System Settings → Privacy & Security → FileVault
- Firewall: System Settings → Network → Firewall
- Enable 2FA on GitHub, Anthropic, and OpenAI accounts

---

## Contributing

Found a bug or want to add a tool? Contributions are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

[MIT License](LICENSE) — free to use, modify, and share.

---

*Built for founders who ship.*
