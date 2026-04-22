# 🚀 mac-setup

> **One script. Full developer setup. Zero headaches.**

[![macOS](https://img.shields.io/badge/macOS-11%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green?logo=gnu-bash)](https://www.gnu.org/software/bash/)

Setting up a new Mac for software development used to mean hours of searching, downloading, and configuring tools one by one. **mac-setup** does all of that for you in a single command.

Whether you're a seasoned engineer or someone setting up their first development machine, this script handles the heavy lifting — installing the right tools, configuring your shell, and getting everything working together correctly.

Works on both **Intel** and **Apple Silicon** Macs (M1, M2, M3, M4 and later).

---

## 📖 Table of Contents

- [Before You Start](#-before-you-start)
- [Quick Start](#-quick-start)
- [What Gets Installed](#-what-gets-installed)
- [Installation Options](#-installation-options)
- [After the Script Finishes](#-after-the-script-finishes)
- [Troubleshooting](#-troubleshooting)
- [Security & Privacy](#-security--privacy)
- [Performance Tips](#-performance-tips)
- [Contributing](#-contributing)

---

## ✅ Before You Start

Take 5 minutes to do these things first — they'll save you time later.

**1. Update macOS**
Go to **System Settings → General → Software Update** and install any pending updates. Some tools require a recent version of macOS to work properly.

**2. Have your Git details ready**
The script will ask for your name and email address to configure Git. These show up on your code commits — use the same name and email as your GitHub or GitLab account.

**3. Make sure you have a stable internet connection**
The script downloads several gigabytes of tools. A wired or strong Wi-Fi connection is recommended.

**4. Set aside 30–60 minutes**
You can walk away during most of the installation — the script runs on its own. Just stay nearby in case a popup asks for your password.

---

## 🚀 Quick Start

Open the **Terminal** app (you can find it in Applications → Utilities) and paste one of the following commands.

### Option A — Run directly (fastest)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/otto-ai-labs/mac-setup/main/devSetup.sh)
```

### Option B — Download first, then run (recommended if you want to review the script)

```bash
# Step 1: Download the repository
git clone https://github.com/otto-ai-labs/mac-setup.git

# Step 2: Move into the folder
cd mac-setup

# Step 3: Make the script runnable
chmod +x devSetup.sh

# Step 4: Run it
./devSetup.sh
```

> 💡 **What is Terminal?** Terminal is an app on your Mac that lets you type commands directly to your computer. Think of it as a text-based way to control your Mac — very powerful for developers.

---

## 📦 What Gets Installed

The script is divided into categories. Here's exactly what you get and why each piece matters.

---

### 🛠 Essential Tools
*The foundation everything else is built on.*

| Tool | What it does |
|------|-------------|
| **Homebrew** | The "app store" for developer tools on Mac. The script uses this to install almost everything else. |
| **Git** | Tracks changes to your code over time and lets you collaborate with others. |
| **SSH Key** | A secure login key automatically created and linked to your Git email. You'll add this to GitHub/GitLab once. |
| **Starship** | Makes your terminal prompt show useful info like which Git branch you're on. |
| **tmux** | Lets you split your terminal into multiple panes and keep sessions running in the background. |
| **Oh My Zsh** | Adds helpful features and plugins to your shell (the terminal environment). |
| **bat, eza, fd, ripgrep, fzf** | Faster and friendlier versions of common terminal commands. |
| **jq, yq** | Tools for reading and editing JSON/YAML files — common in DevOps work. |

---

### 💻 Programming Languages
*The languages your code will be written in.*

| Language | Version | Notes |
|----------|---------|-------|
| **Python** | 3.11 & 3.12 | Includes `pip`, `virtualenv`, `pipenv`, and `poetry` for managing project dependencies. |
| **Node.js** | Latest LTS | Installed via `nvm`, which lets you switch between Node versions per project. |
| **Go** | Latest stable | Popular for backend services and DevOps tooling. |
| **Rust** | Latest stable | Fast, safe systems programming language. |
| **Java** | OpenJDK 17 | Required by many enterprise tools and frameworks. |

---

### ☁️ Cloud & DevOps Tools
*For working with cloud infrastructure and containers.*
*(Can be skipped with `--skip-cloud` — see [Installation Options](#-installation-options))*

| Tool | What it does |
|------|-------------|
| **Docker** | Runs applications in isolated containers — keeps your machine clean. |
| **kubectl** | Command-line tool for managing Kubernetes clusters. |
| **kubectx / k9s** | Easier ways to switch between and visualise Kubernetes clusters. |
| **Helm** | Package manager for Kubernetes applications. |
| **Terraform** | Write code that creates and manages cloud infrastructure. |
| **AWS CLI** | Control Amazon Web Services from the terminal. |
| **Google Cloud SDK** | Control Google Cloud Platform from the terminal. |
| **Azure CLI** | Control Microsoft Azure from the terminal. |
| **Ansible** | Automate configuration and deployment across many servers. |
| **Packer, Vault, Consul, Nomad** | HashiCorp tools for building images, managing secrets, service discovery, and workload scheduling. |
| **Vagrant** | Create and manage virtual machines for local testing. ⚠️ Requires VMware Fusion or Parallels on Apple Silicon — VirtualBox is not supported. |

---

### 🗄 Databases
*Common databases for local development.*
*(Can be skipped with `--skip-databases` — see [Installation Options](#-installation-options))*

| Database | Use case |
|----------|----------|
| **PostgreSQL 15** | The most popular open-source relational database. |
| **MySQL** | Widely used relational database, common in web applications. |
| **Redis** | Lightning-fast in-memory store for caching and queues. |
| **MongoDB** | Document database — stores data in flexible JSON-like format. |

> 💡 Databases are installed but **not auto-started**. Run `brew services start <name>` when you actually need one. This keeps your Mac fast when you're not actively developing.

---

### ✏️ Editors & IDEs
*Where you'll write your code.*

| Tool | What it does |
|------|-------------|
| **Visual Studio Code** | The most popular free code editor. Lightweight and endlessly extensible. |
| **Neovim** | A powerful terminal-based editor, preferred by many senior engineers. |
| **JetBrains Toolbox** | Manages JetBrains IDEs like IntelliJ, PyCharm, GoLand, and more. |

---

### 💬 Productivity Apps

| App | Purpose |
|-----|---------|
| **iTerm2** | A better terminal replacement for the built-in Terminal app. |
| **Slack** | Team messaging. |
| **Zoom** | Video calls. |
| **Notion** | Notes and documentation. |
| **Rectangle** | Snap windows to halves and corners with keyboard shortcuts. |
| **Postman** | Test and explore APIs visually. |

---

## ⚙️ Installation Options

You can customise what gets installed by adding flags to the command.

```bash
./devSetup.sh [OPTIONS]

  --minimal          Install only the essentials (no cloud tools, databases, or productivity apps)
  --skip-cloud       Skip all cloud provider tools (AWS, GCP, Azure, Docker, Kubernetes, etc.)
  --skip-databases   Skip all database installations
  --help             Show available options
```

### Common combinations

```bash
# Just the essentials — languages and CLI tools only
./devSetup.sh --minimal

# Skip cloud tools — good if you only do backend/frontend work
./devSetup.sh --skip-cloud

# Skip local databases — useful if you run everything in Docker
./devSetup.sh --skip-databases

# Skip both cloud tools and databases
./devSetup.sh --skip-cloud --skip-databases
```

---

## 🏗 Architecture Support

The script automatically detects your Mac's chip and configures everything correctly.

| Mac Type | Chip Examples | Status |
|----------|--------------|--------|
| Apple Silicon | M1, M2, M3, M4 (Pro/Max/Ultra) | ✅ Fully supported |
| Intel | 2015–2020 Intel Macs | ✅ Fully supported |

---

## ✅ After the Script Finishes

The script will tell you exactly what to do, but here's a checklist for reference.

**1. Reload your terminal**
```bash
source ~/.zshrc
```
Or just close the terminal window and open a fresh one.

**2. Open Docker.app**
Find it in your Applications folder and open it once. Docker needs to finish its own setup before you can use it.

**3. Add your SSH key to GitHub or GitLab**
The script printed your SSH public key at the end. Copy it and add it here:
- GitHub → [Settings → SSH Keys](https://github.com/settings/keys)
- GitLab → [Profile → SSH Keys](https://gitlab.com/-/profile/keys)

To view it again at any time:
```bash
cat ~/.ssh/id_ed25519.pub
```

**4. Log in to your cloud providers** *(if installed)*
```bash
# Amazon Web Services
aws configure

# Google Cloud Platform
gcloud init

# Microsoft Azure
az login
```

**5. Install VS Code extensions**
Open VS Code, press `Cmd + Shift + X`, and search for:
- Python
- Docker
- Kubernetes
- Terraform
- GitLens
- ESLint
- Prettier

**6. Customise your terminal prompt** *(optional)*
Starship is installed and ready. Browse themes and presets at [starship.rs/presets](https://starship.rs/presets/) and pick one you like.

**7. Restart your Mac**
A restart ensures all the system-level changes (animations, performance tweaks) fully take effect.

---

## 📁 Directory Structure

The script creates a clean folder layout in your home directory:

```
~/Development/
├── projects/     ← Your active coding projects
├── learning/     ← Tutorials, experiments, and practice code
├── tools/        ← Custom tools you build or install manually
└── scripts/      ← Your automation and utility scripts
```

---

## 🔒 Security & Privacy

**A note on `curl | bash`**
This script — and three of the tools it installs (Homebrew, nvm, Rust) — use a pattern where a script is downloaded from the internet and run directly. This is standard practice in the developer community, but it does mean the script runs with your full user permissions. We encourage you to review scripts before running them:
- [Homebrew install script](https://github.com/Homebrew/install)
- [nvm install script](https://github.com/nvm-sh/nvm)
- [rustup install script](https://sh.rustup.rs)

**SSH key passphrase**
By default the script generates an SSH key without a passphrase so the process is non-interactive. If you'd like a passphrase (recommended for keys used on shared or high-security machines), open `devSetup.sh` and remove the `-N ""` from the `ssh-keygen` line — you'll be prompted to set one.

**Other recommendations**
- Enable **FileVault** (full disk encryption): System Settings → Privacy & Security → FileVault
- Enable **Firewall**: System Settings → Network → Firewall
- Enable **two-factor authentication** on all cloud accounts
- Run `brew upgrade` regularly to keep tools up to date

---

## 🐛 Troubleshooting

**The script stopped and asked me to install Xcode tools**
A popup should have appeared. Click Install, wait for it to finish, then run the script again.

**A package failed or timed out**
The script logs everything to a file in your home folder (`~/mac-setup_DATE_TIME.log`). Check the log to see which package failed, then install it manually:
```bash
brew install <package-name>
```

**Docker won't start**
Open Docker.app from your Applications folder, grant any permissions it asks for, and wait for the whale icon in your menu bar to stop animating.

**`nvm` command not found after install**
Run this to load it in your current session:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```
Then close and reopen your terminal — it should work automatically after that.

**`java` command not found**
Reload your shell config:
```bash
source ~/.zshrc
```
Java is installed but needs the PATH update in `.zshrc` to be loaded first.

**Vagrant doesn't work with VirtualBox on my M-series Mac**
VirtualBox does not support Apple Silicon. Install [VMware Fusion](https://www.vmware.com/products/fusion.html) (free for personal use) and configure Vagrant to use it as the provider.

---

## 💡 Performance Tips

**Running databases only when you need them**
Instead of having PostgreSQL, MySQL, and Redis all running in the background all the time:
```bash
# Start a database
brew services start postgresql@15

# Stop it when you're done
brew services stop postgresql@15

# See what's running
brew services list
```

**Using Docker for databases instead**
Many developers prefer running databases inside Docker containers rather than installing them natively. If that's your preference, run the script with `--skip-databases` and use Docker Compose files in your projects.

**Keeping things tidy**
```bash
# Update and clean up Homebrew packages
brew update && brew upgrade && brew cleanup
```

---

## 🤝 Contributing

Found a bug? Want to add a tool? Contributions are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit changes.

---

## 📝 License

[MIT License](LICENSE) — free to use, modify, and share.

---

*Made with ❤️ for the developer community*