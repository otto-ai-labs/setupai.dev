# AI Dev Setup

> **One script. AI development, ready to go.**

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

Set up your Mac for AI development in a single command. Installs Python, Jupyter, Ollama, Claude Code, Codex CLI, and everything else you need to start building AI applications — whether you're a total beginner or an experienced engineer.

Works on both **Intel** and **Apple Silicon** Macs (M1, M2, M3, M4 and later).

**Website:** [setupai.dev](https://setupai.dev)

---

## Table of Contents

- [Before You Start](#before-you-start)
- [Quick Start](#quick-start)
- [What Gets Installed](#what-gets-installed)
- [Installation Options](#installation-options)
- [After the Script Finishes](#after-the-script-finishes)
- [Troubleshooting](#troubleshooting)
- [Security & Privacy](#security--privacy)
- [Performance Tips](#performance-tips)
- [Contributing](#contributing)

---

## Before You Start

Take 5 minutes to do these things first — they'll save you time later.

**1. Update macOS**
Go to **System Settings → General → Software Update** and install any pending updates.

**2. Have your Git details ready**
The script will ask for your name and email address to configure Git. Use the same name and email as your GitHub account.

**3. Make sure you have a stable internet connection**
The script downloads several gigabytes of tools. A wired or strong Wi-Fi connection is recommended.

**4. Set aside 30–60 minutes**
You can walk away during most of the installation. Just stay nearby in case a popup asks for your password.

---

## Quick Start

Open the **Terminal** app (Applications → Utilities) and paste one of the following commands.

### Option A — Run directly (fastest)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh)
```

### Option B — Download first, then run (recommended if you want to review the script)

```bash
# Step 1: Download the repository
git clone https://github.com/otto-ai-labs/setupai.dev.git

# Step 2: Move into the folder
cd setupai.dev

# Step 3: Make the script runnable
chmod +x setup.sh

# Step 4: Run it
./setup.sh
```

> **What is Terminal?** Terminal is an app on your Mac that lets you type commands directly to your computer. Think of it as a text-based way to control your Mac — very powerful for developers.

---

## Individual Scripts

Each script can be run standalone — you don't need to run the full `setup.sh` to use them.

| Script | What it does |
|--------|-------------|
| `setup.sh` | Full AI dev setup — runs all modules in order |
| `bootstrap.sh` | Syncs dotfiles from this repo to your home directory (`~`) |
| `brew.sh` | Installs Xcode CLI tools, Homebrew, and all packages |
| `osx.sh` | Applies macOS system defaults tuned for developers |
| `web.sh` | Sets up JavaScript web development tools (Node, TypeScript, ESLint, Prettier, Vite) |

```bash
# Sync dotfiles to ~
./bootstrap.sh

# Install Homebrew + packages only
./brew.sh

# Apply macOS developer defaults
./osx.sh

# Set up JS web dev tools
./web.sh
```

---

## What Gets Installed

---

### Essential Tools
*The foundation everything else is built on.*

| Tool | What it does |
|------|-------------|
| **Homebrew** | The "app store" for developer tools on Mac. The script uses this to install almost everything else. |
| **Git** | Tracks changes to your code over time and lets you collaborate with others. |
| **SSH Key** | A secure login key automatically created and linked to your Git email. You'll add this to GitHub once. |
| **Starship** | Makes your terminal prompt show useful info like which Git branch you're on. |
| **Oh My Zsh** | Adds helpful features and plugins to your shell. |
| **bat, eza, fd, ripgrep, fzf** | Faster and friendlier versions of common terminal commands. |
| **jq, yq** | Tools for reading and editing JSON/YAML files. |

---

### Programming Languages
*The languages your AI code will be written in.*

| Language | Version | Notes |
|----------|---------|-------|
| **Python** | 3.11 & 3.12 | Includes `pip`, `virtualenv`, and `uv` for managing dependencies. |
| **Jupyter / JupyterLab** | Latest | Interactive notebooks for AI/data experimentation. |
| **Node.js** | Latest LTS | Installed via `nvm`. Required for Claude Code and Codex CLI. |
| **uv** | Latest | Lightning-fast Python package and project manager. |

---

### AI Tools
*For building and running AI applications.*
*(Can be skipped with `--skip-ai-tools` — see [Installation Options](#installation-options))*

| Tool | What it does |
|------|-------------|
| **Ollama** | Run large language models locally on your Mac (Llama, Mistral, Gemma, and more). No API key required. |
| **Claude Code** | Anthropic's official AI coding CLI. Requires an Anthropic API key. |
| **Codex CLI** | OpenAI's coding CLI. Requires an OpenAI API key. |
| **AWS CLI** | Access Amazon Bedrock, SageMaker, and other AI services from the terminal. |
| **Terraform** | Write code that creates and manages AI infrastructure. |

> **Docker:** The script notes where to download Docker Desktop but does not auto-install it, as Docker requires a manual GUI setup. Visit [docker.com](https://www.docker.com/products/docker-desktop/) to download.

---

### Databases
*Common databases for local development.*
*(Can be skipped with `--skip-databases` — see [Installation Options](#installation-options))*

| Database | Use case |
|----------|----------|
| **PostgreSQL 15** | The most popular open-source relational database. Great for storing structured AI outputs. |
| **Redis** | Lightning-fast in-memory store for caching, queues, and AI session data. |
| **SQLite** | Lightweight embedded database — ideal for local AI apps and prototypes. |

> Databases are installed but **not auto-started**. Run `brew services start <name>` when you actually need one. This keeps your Mac fast when you're not actively developing.

---

### Editors & Productivity
*Where you'll write your code.*

| Tool | What it does |
|------|-------------|
| **Visual Studio Code** | The most popular free code editor. Installed with Python, Jupyter, Claude, and GitHub Copilot extensions. |
| **iTerm2** | A better terminal replacement for the built-in Terminal app. |
| **Rectangle** | Snap windows to halves and corners with keyboard shortcuts. |

---

## Installation Options

You can customise what gets installed by adding flags to the command.

```
./setup.sh [OPTIONS]

  --yes, -y          Auto-upgrade all already-installed tools (no prompts)
  --minimal          Install only essentials (languages + shell, no AI tools/databases/apps)
  --skip-ai-tools    Skip AI tools (Ollama, Claude Code, Codex CLI, AWS CLI, Terraform)
  --skip-databases   Skip database installations
  --skip-web         Skip JS web development tools
  --help             Show available options
```

### Passing flags with curl

Flags go **after** the closing parenthesis:

```bash
# Re-run and upgrade everything automatically
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --yes

# Skip databases on re-run
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --skip-databases

# Combine flags
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/setupai.dev/main/setup.sh) --yes --skip-databases
```

### Common combinations

```bash
# Re-run and upgrade all tools without any prompts
./setup.sh --yes

# Just the essentials — languages and CLI tools only
./setup.sh --minimal

# Skip AI tools — good if you're setting up a general dev machine
./setup.sh --skip-ai-tools

# Skip local databases — useful if you run everything in Docker
./setup.sh --skip-databases

# Skip both AI tools and databases
./setup.sh --skip-ai-tools --skip-databases
```

---

## Architecture Support

The script automatically detects your Mac's chip and configures everything correctly.

| Mac Type | Chip Examples | Status |
|----------|--------------|--------|
| Apple Silicon | M1, M2, M3, M4 (Pro/Max/Ultra) | Fully supported |
| Intel | 2015–2020 Intel Macs | Fully supported |

---

## After the Script Finishes

The script will tell you exactly what to do, but here's a checklist for reference.

**1. Reload your terminal**
```bash
source ~/.zshrc
```
Or just close the terminal window and open a fresh one.

**2. Add your SSH key to GitHub**
The script printed your SSH public key. Copy it and add it at [github.com/settings/keys](https://github.com/settings/keys).

To view it again:
```bash
cat ~/.ssh/id_ed25519.pub
```

**3. Set up your AI API keys**
```bash
# Anthropic (for Claude Code) — get at console.anthropic.com
export ANTHROPIC_API_KEY='sk-ant-...'

# OpenAI (for Codex CLI) — get at platform.openai.com
export OPENAI_API_KEY='sk-...'
```

Add these lines to your `~/.zshrc` so they persist across sessions.

**4. Try Ollama (run a local model — no API key needed)**
```bash
ollama run llama3
```

**5. Launch Jupyter and start experimenting**
```bash
jupyter lab
# or use the installed shortcut:
jl
```

**6. Start coding with Claude Code**
```bash
claude
```

**7. Customise your terminal prompt** *(optional)*
Starship is installed and ready. Browse themes at [starship.rs/presets](https://starship.rs/presets/).

**8. Restart your Mac**
A restart ensures all system-level changes (animations, performance tweaks) fully take effect.

---

## Directory Structure

The script creates a clean folder layout in your home directory:

```
~/Development/
├── projects/          ← Your active coding projects
├── learning/          ← Tutorials, experiments, and practice code
├── tools/             ← Custom tools you build or install manually
├── scripts/           ← Your automation and utility scripts
└── ai-experiments/    ← AI prototypes, notebooks, and model experiments
```

---

## Security & Privacy

**A note on `curl | bash`**
This script — and two of the tools it installs (Homebrew and nvm) — use a pattern where a script is downloaded from the internet and run directly. This is standard practice in the developer community, but it does mean the script runs with your full user permissions. We encourage you to review scripts before running them:
- [Homebrew install script](https://github.com/Homebrew/install)
- [nvm install script](https://github.com/nvm-sh/nvm)

**SSH key passphrase**
By default the script generates an SSH key without a passphrase so the process is non-interactive. If you'd like a passphrase, open `setup.sh` and remove the `-N ""` from the `ssh-keygen` line — you'll be prompted to set one.

**Other recommendations**
- Enable **FileVault** (full disk encryption): System Settings → Privacy & Security → FileVault
- Enable **Firewall**: System Settings → Network → Firewall
- Enable **two-factor authentication** on your GitHub, Anthropic, and OpenAI accounts
- Run `brew upgrade` regularly to keep tools up to date

---

## Troubleshooting

**The script stopped and asked me to install Xcode tools**
A popup should have appeared. Click Install, wait for it to finish, then run the script again.

**A package failed or timed out**
The script logs everything to a file in your home folder (`~/ai-dev-setup_DATE_TIME.log`). Check the log to see which package failed, then install it manually:
```bash
brew install <package-name>
```

**`nvm` command not found after install**
Run this to load it in your current session:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
Then close and reopen your terminal — it should work automatically after that.

**`ollama` command not found**
Reload your shell:
```bash
source ~/.zshrc
```
If Ollama still isn't found, install it manually: `brew install ollama`

**`claude` command not found after install**
Claude Code is installed via npm. Make sure nvm and Node are loaded:
```bash
source ~/.zshrc
npm install -g @anthropic-ai/claude-code
```

**Jupyter won't start**
Make sure Python and pip are working correctly:
```bash
pip3 install --upgrade jupyter jupyterlab
```
Then try `jupyter lab` again.

**VS Code `code` command not found**
The `code` CLI is only available after you've opened VS Code at least once. Open Visual Studio Code from your Applications folder, then try again.

---

## Performance Tips

**Running databases only when you need them**
Instead of having PostgreSQL and Redis running in the background all the time:
```bash
# Start a database
brew services start postgresql@15

# Stop it when you're done
brew services stop postgresql@15

# See what's running
brew services list
```

**Running Ollama on demand**
Ollama loads models into memory and can use significant RAM. Start it only when you need it:
```bash
ollama run llama3
# Press Ctrl+D or type /bye to exit
```

**Fast Python environments with uv**
`uv` is dramatically faster than pip for creating virtual environments:
```bash
# Create a new project environment
uv venv

# Install packages
uv pip install numpy pandas

# Or use uv's project management
uv init my-ai-project
cd my-ai-project
uv add anthropic openai
```

**Keeping things tidy**
```bash
# Update and clean up Homebrew packages
brew update && brew upgrade && brew cleanup
```

---

## Contributing

Found a bug? Want to add a tool? Contributions are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit changes.

---

## License

[MIT License](LICENSE) — free to use, modify, and share.

---

*Made for the AI builder community*
