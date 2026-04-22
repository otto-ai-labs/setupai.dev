#!/bin/bash
# Steps 12–14: Development directories, macOS perf tweaks, Homebrew cleanup.

################################################################################
# 12. Development Directory Structure
################################################################################
log_info "Step 12: Creating development directory structure..."

mkdir -p "$HOME/Development/"{projects,learning,tools,scripts,ai-experiments}
mkdir -p "$HOME/.config"

log_success "Development directories created"
echo ""

################################################################################
# 13. Performance Optimizations
################################################################################
log_info "Step 13: Applying performance optimizations..."

defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g QLPanelAnimationDuration -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.universalaccess reduceTransparency -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1

log_success "Performance optimizations applied"
log_warning "You may need to restart for all changes to take effect"
echo ""

################################################################################
# 14. Cleanup
################################################################################
log_info "Step 14: Cleaning up Homebrew cache..."
# FIX: brew cleanup reclaims disk space from cached downloads (can be several GB)
brew cleanup
log_success "Homebrew cache cleaned"
echo ""
