#!/bin/bash
# zmake uninstall script
# Usage: ./uninstall.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1"
    exit 1
}

# Check if zmake is installed
check_installation() {
    if ! command -v zmake &> /dev/null; then
        warning "zmake is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Remove files installed by different methods
uninstall_zmake() {
    info "Uninstalling zmake..."
    
    local removed_something=false
    
    # Check for pacman-installed zmake
    if pacman -Q zmake &> /dev/null; then
        info "Removing zmake package..."
        sudo pacman -Rs zmake
        removed_something=true
    fi
    
    # Check for manually installed zmake in /usr/local/bin
    if [[ -f "/usr/local/bin/zmake" ]]; then
        info "Removing /usr/local/bin/zmake..."
        sudo rm -f /usr/local/bin/zmake
        removed_something=true
    fi
    
    # Remove documentation
    if [[ -d "/usr/local/share/doc/zmake" ]]; then
        info "Removing documentation..."
        sudo rm -rf /usr/local/share/doc/zmake
        removed_something=true
    fi
    
    # Remove examples
    if [[ -d "/usr/local/share/zmake" ]]; then
        info "Removing examples..."
        sudo rm -rf /usr/local/share/zmake
        removed_something=true
    fi
    
    # Remove shell completions
    if [[ -f "/usr/share/bash-completion/completions/zmake" ]]; then
        info "Removing bash completion..."
        sudo rm -f /usr/share/bash-completion/completions/zmake
        removed_something=true
    fi
    
    if [[ -f "/usr/share/zsh/site-functions/_zmake" ]]; then
        info "Removing zsh completion..."
        sudo rm -f /usr/share/zsh/site-functions/_zmake
        removed_something=true
    fi
    
    # Remove cache directory (optional)
    local cache_dir="$HOME/.cache/zmake"
    if [[ -d "$cache_dir" ]]; then
        read -p "Remove cache directory ($cache_dir)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Removing cache directory..."
            rm -rf "$cache_dir"
            removed_something=true
        fi
    fi
    
    if [[ "$removed_something" == true ]]; then
        success "zmake has been uninstalled"
    else
        warning "No zmake installation found to remove"
    fi
}

# Main uninstall logic
main() {
    info "🗑️  zmake uninstaller"
    echo
    
    # Parse command line arguments
    local force_remove=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_remove=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --force      Force removal without confirmation"
                echo "  --help       Show this help message"
                exit 0
                ;;
            *)
                warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Confirm uninstallation
    if [[ "$force_remove" != true ]]; then
        echo "This will remove zmake and its associated files."
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    # Uninstall zmake
    uninstall_zmake
    
    # Verify removal
    if ! command -v zmake &> /dev/null; then
        success "zmake has been completely removed"
    else
        warning "zmake command still found in PATH - manual cleanup may be required"
    fi
}

# Run main function with all arguments
main "$@"