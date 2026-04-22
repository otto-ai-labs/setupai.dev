#!/bin/bash
# Shared utilities — colors, logging, and install helpers.
# Sourced by setup.sh before any modules are called.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" &>/dev/null
}

# Ask whether to upgrade an already-installed tool.
# Usage: prompt_upgrade "git" "2.43.0"
# Returns 0 (yes/upgrade) or 1 (no/skip)
# Set UPGRADE_ALL=true (via --yes flag) to auto-answer yes to all.
prompt_upgrade() {
    local name="$1"
    local version="$2"
    local answer
    echo -e "${YELLOW}[UPGRADE]${NC} $name is already installed (${version})"
    if [[ "${UPGRADE_ALL:-false}" == true ]]; then
        echo "         Auto-upgrading (--yes)"
        return 0
    fi
    read -r -p "         Upgrade to latest? [y/N] " answer </dev/tty
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Custom timeout — macOS has no native `timeout` command.
run_with_timeout() {
    local timeout_duration=$1
    shift
    local command_to_run=("$@")

    "${command_to_run[@]}" &
    local cmd_pid=$!

    local count=0
    while kill -0 $cmd_pid 2>/dev/null; do
        if [ $count -ge $timeout_duration ]; then
            kill -TERM $cmd_pid 2>/dev/null
            sleep 1
            kill -KILL $cmd_pid 2>/dev/null
            wait $cmd_pid 2>/dev/null
            return 124
        fi
        sleep 1
        ((count++))
    done

    wait $cmd_pid
    return $?
}

# FIX: Timeout increased to 300s — large packages like python@3.12 easily
#      exceed 60s on first install.
brew_install_with_timeout() {
    local timeout_duration=300
    local package="$1"

    log_info "Installing $package (with ${timeout_duration}s timeout)..."

    if run_with_timeout "$timeout_duration" brew install "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}

brew_install_cask_with_timeout() {
    local timeout_duration=300
    local package="$1"

    log_info "Installing $package (cask, with ${timeout_duration}s timeout)..."

    if run_with_timeout "$timeout_duration" brew install --cask "$package"; then
        log_success "$package installed successfully"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            log_error "$package installation timed out after ${timeout_duration}s"
            log_warning "You can try installing manually later: brew install --cask $package"
        else
            log_error "$package installation failed"
        fi
        return 1
    fi
}
