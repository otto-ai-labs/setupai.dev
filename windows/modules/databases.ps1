# windows/modules/databases.ps1
# Step 7: Databases — installs only what the user selected.
# Selections are read from $env:SEL_DB (comma-separated keys).
#
# Notes:
#   - PostgreSQL  → winget install PostgreSQL.PostgreSQL
#   - Redis       → Scoop (winget does not have a Redis package)
#   - SQLite      → winget install SQLite.SQLite
#   - DuckDB      → winget install DuckDB.cli
#
# Dot-sourced by setup.ps1:
#   . "$PSScriptRoot\modules\databases.ps1"

. "$PSScriptRoot\utils.ps1"

if ($env:SKIP_DATABASES -eq "true") {
    Write-Info "Step 7: Skipping databases (--SkipDatabases flag)"
    Write-Host ""
    return
}

Write-Info "Step 7: Installing database tools..."

function Test-DbSelected {
    param([string]$Key)
    if ([string]::IsNullOrEmpty($env:SEL_DB)) { return $true }
    $keys = $env:SEL_DB -split ","
    return Test-ArrayContains -Array $keys -Value $Key
}

# ── PostgreSQL 15 ─────────────────────────────────────────────────────────────

if (Test-DbSelected "postgresql") {
    # Check for any existing PostgreSQL installation
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
    $pgCmd     = Test-CommandExists "psql"
    if ($pgService -or $pgCmd) {
        Write-Success "PostgreSQL already installed"
    }
    else {
        # winget PostgreSQL package installs the latest stable (15.x / 16.x).
        # The installer is interactive by default; --silent suppresses most dialogs.
        Write-Info "Installing PostgreSQL..."
        Install-WithWinget -Id "PostgreSQL.PostgreSQL" -Name "PostgreSQL" -TimeoutSeconds 300
        Write-Info "Note: PostgreSQL service is NOT auto-started."
        Write-Info "Start manually: net start postgresql-x64-*"
        Write-Info "Or use pgAdmin (installed alongside PostgreSQL)."
    }
}

# ── Redis — via Scoop (not available in Winget) ───────────────────────────────

if (Test-DbSelected "redis") {
    if (Test-CommandExists "redis-server") {
        Write-Success "Redis already installed"
    }
    else {
        Write-Info "Redis is not in Winget — installing via Scoop..."
        # Ensure the 'main' bucket is present (it's the default but good to confirm)
        Install-WithScoop -Package "redis" -Name "Redis" -TimeoutSeconds 120
        Write-Info "Note: Redis is NOT auto-started."
        Write-Info "Start manually: redis-server"
        Write-Info "Or run as a service: redis-server --service-install"
    }
}

# ── SQLite ────────────────────────────────────────────────────────────────────

if (Test-DbSelected "sqlite") {
    # sqlite3.exe ships with many tools — check explicitly via winget list
    if (Test-CommandExists "sqlite3") {
        Write-Success "SQLite already installed"
    }
    else {
        Install-WithWinget -Id "SQLite.SQLite" -Name "SQLite" -TimeoutSeconds 60
    }
}

# ── DuckDB ────────────────────────────────────────────────────────────────────

if (Test-DbSelected "duckdb") {
    if (Test-CommandExists "duckdb") {
        Write-Success "DuckDB already installed"
    }
    else {
        Install-WithWinget -Id "DuckDB.cli" -Name "DuckDB" -TimeoutSeconds 60
    }
}

Write-Success "Database tools installed"
Write-Info "Note: Databases are not auto-started. Start each service manually when needed."
Write-Host ""
