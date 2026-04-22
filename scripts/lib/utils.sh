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

# ── Interactive checkbox selector ────────────────────────────────────────────
# Usage:
#   checkbox_select "Category title" "description line" selected_var \
#       "KEY|Label|description|default" ...
#
# Each item: "KEY|Label|short description|default"
#   default = "on" (pre-selected) or "off"
#
# On return, selected_var is set in the CALLER's scope via a temp file trick
# because bash functions can't set variables in the parent directly across
# subshell boundaries. We print selected keys to stdout and the caller reads
# them with:   mapfile -t MY_ARRAY < <(checkbox_select ...)
#
# Controls: ↑/↓ move, Space toggle, A select all, N deselect all, Enter confirm
#
# When UPGRADE_ALL=true (--yes flag) or stdin is not a tty, returns all
# items that have default="on" immediately without drawing any UI.
# ─────────────────────────────────────────────────────────────────────────────
checkbox_select() {
    local title="$1"
    local subtitle="$2"
    shift 2
    local items=("$@")   # "KEY|Label|desc|default"

    local n=${#items[@]}
    local -a keys labels descs selected

    for i in "${!items[@]}"; do
        IFS='|' read -r k l d def <<< "${items[$i]}"
        keys[$i]="$k"
        labels[$i]="$l"
        descs[$i]="$d"
        if [[ "$def" == "on" ]]; then
            selected[$i]=1
        else
            selected[$i]=0
        fi
    done

    # Non-interactive / --yes: return defaults immediately
    if [[ "${UPGRADE_ALL:-false}" == true ]] || [[ ! -t 0 ]]; then
        for i in "${!keys[@]}"; do
            [[ "${selected[$i]}" -eq 1 ]] && echo "${keys[$i]}"
        done
        return
    fi

    # Save terminal state, enable raw input
    local saved_tty
    saved_tty=$(stty -g </dev/tty)
    stty raw -echo </dev/tty

    local cursor=0   # which row the highlight is on

    _cb_draw() {
        # Move cursor to top of our block and redraw
        local i
        # Title
        tput el </dev/tty
        printf "\r  ${BLUE}%s${NC}\n" "$title" >/dev/tty
        tput el </dev/tty
        printf "\r  ${NC}%s${NC}\n" "$subtitle" >/dev/tty
        tput el </dev/tty
        printf "\r  %s\n" "$(printf '%0.s─' {1..60})" >/dev/tty

        for i in "${!keys[@]}"; do
            tput el </dev/tty
            local box desc_text
            if [[ "${selected[$i]}" -eq 1 ]]; then
                box="${GREEN}[x]${NC}"
            else
                box="[ ]"
            fi
            if [[ "$i" -eq "$cursor" ]]; then
                printf "\r  ${YELLOW}▶ %b %-22s${NC} %s\n" \
                    "$box" "${labels[$i]}" "${descs[$i]}" >/dev/tty
            else
                printf "\r    %b %-22s${NC} %s\n" \
                    "$box" "${labels[$i]}" "${descs[$i]}" >/dev/tty
            fi
        done
        tput el </dev/tty
        printf "\r  %s\n" "$(printf '%0.s─' {1..60})" >/dev/tty
        tput el </dev/tty
        printf "\r  ${NC}↑/↓ move  Space toggle  A all  N none  Enter confirm${NC}\n" >/dev/tty

        # Move back up to redraw next time
        local total_lines=$(( n + 5 ))
        tput cuu "$total_lines" </dev/tty
    }

    # Initial draw
    printf '\n%.0s' {1..20} >/dev/tty   # reserve space
    local total_lines=$(( n + 5 ))
    tput cuu "$total_lines" </dev/tty
    _cb_draw

    while true; do
        local key
        # Read one char; handle escape sequences (arrow keys = ESC [ A/B)
        IFS= read -r -s -n1 key </dev/tty
        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -r -s -n1 -t 0.1 seq1 </dev/tty
            IFS= read -r -s -n1 -t 0.1 seq2 </dev/tty
            key="${key}${seq1}${seq2}"
        fi

        case "$key" in
            $'\x1b[A'|k|K)   # Up arrow or k
                (( cursor > 0 )) && (( cursor-- ))
                ;;
            $'\x1b[B'|j|J)   # Down arrow or j
                (( cursor < n - 1 )) && (( cursor++ ))
                ;;
            ' ')              # Space — toggle
                if [[ "${selected[$cursor]}" -eq 1 ]]; then
                    selected[$cursor]=0
                else
                    selected[$cursor]=1
                fi
                ;;
            a|A)              # Select all
                for i in "${!keys[@]}"; do selected[$i]=1; done
                ;;
            n|N)              # Deselect all
                for i in "${!keys[@]}"; do selected[$i]=0; done
                ;;
            $'\r'|$'\n'|'')  # Enter — confirm
                break
                ;;
        esac
        _cb_draw
    done

    # Restore terminal, move past the drawn block
    stty "$saved_tty" </dev/tty
    local total_lines=$(( n + 5 ))
    tput cud "$total_lines" </dev/tty
    printf '\n' >/dev/tty

    # Output selected keys to stdout (caller captures with mapfile/read)
    for i in "${!keys[@]}"; do
        [[ "${selected[$i]}" -eq 1 ]] && echo "${keys[$i]}"
    done
}

# Helper: check if a key is in a bash array
# Usage: array_contains MY_ARRAY "KEY"
array_contains() {
    local -n _arr="$1"
    local val="$2"
    local item
    for item in "${_arr[@]}"; do
        [[ "$item" == "$val" ]] && return 0
    done
    return 1
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
