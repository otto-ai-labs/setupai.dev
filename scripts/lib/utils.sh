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
    # Use indexed arrays with plain variables for bash 3.2 compatibility
    local keys=() labels=() descs=() selected=()
    local i k l d def

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

    # Non-interactive / --yes: return defaults immediately without drawing UI
    if [[ "${UPGRADE_ALL:-false}" == true ]] || [[ ! -t 1 ]]; then
        for i in "${!keys[@]}"; do
            [[ "${selected[$i]}" -eq 1 ]] && echo "${keys[$i]}"
        done
        return
    fi

    # Build escape sequences at runtime — bash 3.2 $'...' in case patterns
    # is unreliable; comparing assembled strings works correctly.
    local ESC=$'\033'
    local UP="${ESC}[A"
    local DOWN="${ESC}[B"
    local SEP="----------------------------------------------------------------"

    local cursor=0
    local total_lines=$(( n + 5 ))

    _cb_draw() {
        local i box
        tput cuu "$total_lines" >/dev/tty
        printf "\r  \033[0;34m%-60s\033[0m\n" "$title" >/dev/tty
        printf "\r  %-60s\n" "$subtitle" >/dev/tty
        printf "\r  %s\n" "$SEP" >/dev/tty
        for i in "${!keys[@]}"; do
            if [[ "${selected[$i]}" -eq 1 ]]; then
                box="\033[0;32m[x]\033[0m"
            else
                box="[ ]"
            fi
            if [[ "$i" -eq "$cursor" ]]; then
                printf "\r  \033[1;33m> %b %-24s\033[0m %s\n" \
                    "$box" "${labels[$i]}" "${descs[$i]}" >/dev/tty
            else
                printf "\r    %b %-24s %s\n" \
                    "$box" "${labels[$i]}" "${descs[$i]}" >/dev/tty
            fi
        done
        printf "\r  %s\n" "$SEP" >/dev/tty
        printf "\r  \033[0;90mUp/Down: move  Space/Enter: toggle  D: done  A: all  N: none\033[0m\n" >/dev/tty
    }

    # Reserve space for the menu then draw it
    for i in $(seq 1 $total_lines); do printf '\n' >/dev/tty; done
    _cb_draw

    # Save terminal state and switch to raw input
    local saved_tty
    saved_tty=$(stty -g </dev/tty)
    stty -echo -icanon min 1 time 0 </dev/tty

    while true; do
        local c1 c2 c3
        # Read one byte at a time from /dev/tty
        IFS= read -r -s -n1 c1 </dev/tty

        if [[ "$c1" == "$ESC" ]]; then
            # Read two more bytes for escape sequence (arrow keys)
            IFS= read -r -s -n1 c2 </dev/tty
            IFS= read -r -s -n1 c3 </dev/tty
            local seq="${c1}${c2}${c3}"
            if [[ "$seq" == "$UP" ]]; then
                (( cursor > 0 )) && (( cursor-- ))
            elif [[ "$seq" == "$DOWN" ]]; then
                (( cursor < n - 1 )) && (( cursor++ ))
            fi
        else
            case "$c1" in
                ' ')          # Space — toggle current item
                    if [[ "${selected[$cursor]}" -eq 1 ]]; then
                        selected[$cursor]=0
                    else
                        selected[$cursor]=1
                    fi
                    ;;
                '')           # Enter — toggle current item
                    if [[ "${selected[$cursor]}" -eq 1 ]]; then
                        selected[$cursor]=0
                    else
                        selected[$cursor]=1
                    fi
                    ;;
                d|D)          # D — done/confirm
                    break
                    ;;
                a|A)          # A — select all
                    for i in "${!keys[@]}"; do selected[$i]=1; done
                    ;;
                n|N)          # N — deselect all
                    for i in "${!keys[@]}"; do selected[$i]=0; done
                    ;;
            esac
        fi
        _cb_draw
    done

    # Restore terminal state
    stty "$saved_tty" </dev/tty
    printf '\n' >/dev/tty

    # Output selected keys to stdout
    for i in "${!keys[@]}"; do
        [[ "${selected[$i]}" -eq 1 ]] && echo "${keys[$i]}"
    done
}

# Helper: check if a key is in a bash array
# Usage: array_contains MY_ARRAY "KEY"
# Uses eval for bash 3.2 compatibility (macOS system bash).
array_contains() {
    local arr_name="$1"
    local val="$2"
    local item
    local arr_copy
    eval "arr_copy=(\"\${${arr_name}[@]}\")"
    for item in "${arr_copy[@]}"; do
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
