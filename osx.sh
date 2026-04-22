#!/usr/bin/env bash

################################################################################
# osx.sh — macOS system defaults for developers
#
# Sets sensible macOS defaults across all key system areas:
#   - General UI & UX
#   - Input devices (trackpad, keyboard, mouse)
#   - Screen & display
#   - Finder
#   - Dock & Mission Control
#   - Safari
#   - Terminal & iTerm2
#   - Activity Monitor
#   - TextEdit & other apps
#
# Most changes take effect immediately. A restart is recommended for all
# changes to fully apply.
#
# Usage:
#   ./osx.sh
#
# Inspired by:
#   https://github.com/donnemartin/dev-setup/blob/master/osx.sh
#   https://github.com/mathiasbynens/dotfiles/blob/master/.macos
################################################################################

# Keep sudo alive — skip if already managed by setup.sh
if [[ -z "$SETUP_RUNNING" ]]; then
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [[ -z "$SETUP_RUNNING" ]]; then
    echo ""
    echo "======================================================"
    echo " osx.sh — macOS developer defaults"
    echo "======================================================"
    echo ""
fi

# ── General UI / UX ──────────────────────────────────────────────────────────
log_info "General UI / UX..."

# NOTE: Disabling boot sound via nvram triggers a TCC privacy popup on
# macOS Ventura+ which can kill the terminal session. Skipped intentionally.
# To disable boot sound manually: System Settings → Sound → uncheck "Play sound on startup"

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable automatic capitalisation, smart dashes, smart quotes, auto-correct
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable window resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

log_success "General UI / UX done"
echo ""

# ── Input devices ─────────────────────────────────────────────────────────────
log_info "Input devices (trackpad, keyboard, mouse)..."

# Trackpad: enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom-right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

# Enable full keyboard access (Tab moves focus to all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys — enable key repeat instead
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Set language and locale
# Respects SYSTEM_LOCALE env var if set, otherwise leaves system locale unchanged
if [[ -n "$SYSTEM_LOCALE" ]]; then
    defaults write NSGlobalDomain AppleLocale -string "$SYSTEM_LOCALE"
fi
# Use metric units (Centimeters) — change to false if you prefer Imperial
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true

log_success "Input devices done"
echo ""

# ── Screen ────────────────────────────────────────────────────────────────────
log_info "Screen settings..."

# Require password immediately after screensaver or sleep
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"

# Disable screenshot thumbnail preview
defaults write com.apple.screencapture show-thumbnail -bool false

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 1

log_success "Screen settings done"
echo ""

# ── Finder ────────────────────────────────────────────────────────────────────
log_info "Finder settings..."

# Allow quitting via Cmd+Q (hides Desktop icons)
defaults write com.apple.finder QuitMenuItem -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path in Finder title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories; remove delay
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing-delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes: icnv, clmv, glyv, Nlsv (icon, column, gallery, list)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show the ~/Library folder
chflags nohidden ~/Library 2>/dev/null || true

# NOTE: sudo chflags nohidden /Volumes triggers a TCC privacy popup on
# macOS Ventura+ which can kill the terminal session. Skipped intentionally.
# /Volumes is visible in Finder via Go → Computer without this change.

# Expand File Info panes: General, Open with, Sharing & Permissions
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

log_success "Finder settings done"
echo ""

# ── Dock & Mission Control ────────────────────────────────────────────────────
log_info "Dock & Mission Control..."

# Set Dock icon size to 48 pixels
defaults write com.apple.dock tilesize -int 48

# Enable magnification; set magnified size
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 72

# Minimise windows into their app icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open apps
defaults write com.apple.dock show-process-indicators -bool true

# Animate opening apps — disable for speed
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Auto-hide Dock; remove hide/show delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0

# Make hidden app icons translucent
defaults write com.apple.dock showhidden -bool true

# Don't show recently used apps in Dock
defaults write com.apple.dock show-recents -bool false

# Hot corners:
# Possible values:
#  0  — no-op       1  — Launchpad     2  — Mission Control
#  3  — App Exposé  4  — Desktop       5  — Start screensaver
#  6  — Disable SS  7  — Dashboard     10 — Put display to sleep
#  11 — Launchpad   12 — Notification Centre  13 — Lock Screen
# Bottom-left → Start screensaver
defaults write com.apple.dock wvous-bl-corner   -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0
# Bottom-right → Mission Control
defaults write com.apple.dock wvous-br-corner   -int 2
defaults write com.apple.dock wvous-br-modifier -int 0

log_success "Dock & Mission Control done"
echo ""

# ── Safari ────────────────────────────────────────────────────────────────────
log_info "Safari settings..."

# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari's home page to about:blank for faster loading
defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from opening safe files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Enable Developer menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item to show Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Disable AutoFill
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false

# Enable Do Not Track
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

log_success "Safari settings done"
echo ""

# ── Terminal & iTerm2 ─────────────────────────────────────────────────────────
log_info "Terminal & iTerm2..."

# Use UTF-8 in Terminal
defaults write com.apple.terminal StringEncodings -array 4

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Don't display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

log_success "Terminal & iTerm2 done"
echo ""

# ── Activity Monitor ──────────────────────────────────────────────────────────
log_info "Activity Monitor..."

# Show the main window when launching
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

log_success "Activity Monitor done"
echo ""

# ── TextEdit ──────────────────────────────────────────────────────────────────
log_info "TextEdit..."

# Use plain text mode as default
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

log_success "TextEdit done"
echo ""

# ── App Store ─────────────────────────────────────────────────────────────────
log_info "App Store..."

# Enable automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for updates daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in the background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install system data files and security updates automatically
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

log_success "App Store done"
echo ""

# ── Kill affected apps ────────────────────────────────────────────────────────
log_info "Restarting affected apps..."
for app in \
    "Activity Monitor" "cfprefsd" "Dock" "Finder" \
    "Safari" "SystemUIServer" "Terminal"; do
    killall "$app" &>/dev/null || true
done

if [[ -z "$SETUP_RUNNING" ]]; then
    echo ""
    log_success "======================================================"
    log_success " osx.sh complete!"
    log_success "======================================================"
    echo ""
fi
log_warning "Some changes require a full restart to take effect."
