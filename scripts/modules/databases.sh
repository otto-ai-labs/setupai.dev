#!/bin/bash
# Step 7: Databases — installs only what the user selected.

if [[ "$SKIP_DATABASES" == true ]]; then
    log_info "Step 7: Skipping databases (--skip-databases flag)"
    echo ""
    return 0
fi

log_info "Step 7: Installing database tools..."

_db_selected() {
    local key="$1"
    if [[ -z "${SEL_DB+x}" ]]; then return 0; fi
    array_contains SEL_DB "$key"
}

# PostgreSQL 15
if _db_selected postgresql; then
    if ! brew list postgresql@15 &>/dev/null; then
        brew_install_with_timeout postgresql@15 || true
    else
        log_success "postgresql@15 already installed"
    fi
fi

# Redis
if _db_selected redis; then
    if ! brew list redis &>/dev/null; then
        brew_install_with_timeout redis || true
    else
        log_success "redis already installed"
    fi
fi

# SQLite: use brew list, not command_exists — /usr/bin/sqlite3 ships with macOS
if _db_selected sqlite; then
    if ! brew list sqlite3 &>/dev/null; then
        brew_install_with_timeout sqlite3 || true
    else
        log_success "sqlite3 already installed"
    fi
fi

# DuckDB — fast in-process analytical database
if _db_selected duckdb; then
    if ! brew list duckdb &>/dev/null; then
        brew_install_with_timeout duckdb || true
    else
        log_success "duckdb already installed"
    fi
fi

log_success "Database tools installed"
log_info "Note: Databases are not auto-started. Use 'brew services start <db>' when needed"
echo ""
