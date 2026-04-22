#!/bin/bash
# Step 7: Databases — PostgreSQL 15, Redis, SQLite.

if [[ "$SKIP_DATABASES" == true ]]; then
    log_info "Step 7: Skipping databases (--skip-databases flag)"
    echo ""
    return 0
fi

log_info "Step 7: Installing database tools..."

if ! brew list postgresql@15 &>/dev/null; then
    brew_install_with_timeout postgresql@15 || true
else
    log_success "postgresql@15 already installed"
fi

if ! brew list redis &>/dev/null; then
    brew_install_with_timeout redis || true
else
    log_success "redis already installed"
fi

# SQLite: use brew list, not command_exists — /usr/bin/sqlite3 ships with macOS
# and would cause command_exists to always return true.
if ! brew list sqlite3 &>/dev/null; then
    brew_install_with_timeout sqlite3 || true
else
    log_success "sqlite3 already installed"
fi

log_success "Database tools installed"
log_info "Note: Databases are not auto-started. Use 'brew services start <db>' when needed"
echo ""
