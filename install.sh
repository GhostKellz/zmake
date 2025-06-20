#!/bin/bash
# zmake installer script - One-liner installer for zmake
# Usage: curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
fi

# Check if we're on Arch Linux
if ! command -v pacman &> /dev/null; then
    error "This installer is designed for Arch Linux systems with pacman"
fi

# Check for required dependencies
check_dependencies() {
    info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for Zig
    if ! command -v zig &> /dev/null; then
        missing_deps+=("zig")
    else
        local zig_version=$(zig version)
        info "Found Zig: $zig_version"
        
        # Check if Zig version is >= 0.15.0 (simplified check)
        if [[ $(echo "$zig_version" | cut -d. -f1-2) < "0.15" ]]; then
            warning "Zig version $zig_version may be too old (need >= 0.15.0)"
        fi
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Install missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        info "Installing missing dependencies: ${missing_deps[*]}"
        sudo pacman -S --needed "${missing_deps[@]}"
    fi
}

# Install zmake
install_zmake() {
    local install_dir="/tmp/zmake-install-$$"
    local install_method="$1"
    
    info "Installing zmake using method: $install_method"
    
    case "$install_method" in
        "source")
            install_from_source "$install_dir"
            ;;
        "aur")
            install_from_aur
            ;;
        "package")
            install_from_package "$install_dir"
            ;;
        *)
            error "Unknown install method: $install_method"
            ;;
    esac
}

# Install from source (git clone and build)
install_from_source() {
    local temp_dir="$1"
    
    info "Installing zmake from source..."
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Clone repository
    info "Cloning zmake repository..."
    git clone https://github.com/ghostkellz/zmake.git
    cd zmake
    
    # Build zmake
    info "Building zmake with Zig..."
    zig build -Drelease-fast
    
    # Install binary
    info "Installing zmake to /usr/local/bin..."
    sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake
    
    # Install documentation
    sudo mkdir -p /usr/local/share/doc/zmake
    sudo cp README.md DOCS.md COMMANDS.md INSTALL.md /usr/local/share/doc/zmake/
    
    # Install shell completions
    info "Installing shell completions..."
    if [[ -d "completions" ]]; then
        # Bash completion
        sudo mkdir -p /usr/share/bash-completion/completions
        sudo cp completions/zmake.bash /usr/share/bash-completion/completions/zmake
        
        # Zsh completion  
        sudo mkdir -p /usr/share/zsh/site-functions
        sudo cp completions/_zmake /usr/share/zsh/site-functions/_zmake
        
        success "Shell completions installed"
        info "Restart your shell or run 'source ~/.bashrc' to enable completions"
    else
        warning "Shell completion files not found"
    fi
    
    # Install examples
    sudo mkdir -p /usr/local/share/zmake/examples
    sudo cp -r examples/* /usr/local/share/zmake/examples/
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
    
    success "zmake installed to /usr/local/bin/zmake"
}

# Install from AUR (if someone publishes it)
install_from_aur() {
    info "Installing zmake from AUR..."
    
    # Check if an AUR helper is available
    if command -v yay &> /dev/null; then
        yay -S zmake
    elif command -v paru &> /dev/null; then
        paru -S zmake
    elif command -v auracle &> /dev/null; then
        auracle clone zmake
        cd zmake
        makepkg -si
        cd ..
        rm -rf zmake
    else
        warning "No AUR helper found. Installing manually..."
        install_aur_manual
    fi
}

# Manual AUR installation
install_aur_manual() {
    local temp_dir="/tmp/zmake-aur-$$"
    
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    info "Cloning AUR package..."
    git clone https://aur.archlinux.org/zmake.git
    cd zmake
    
    info "Building package with makepkg..."
    makepkg -si
    
    cd /
    rm -rf "$temp_dir"
}

# Install from pre-built package (if we had releases)
install_from_package() {
    local temp_dir="$1"
    
    info "Installing zmake from pre-built package..."
    warning "Pre-built packages not yet available. Falling back to source installation."
    install_from_source "$temp_dir"
}

# Main installation logic
main() {
    info "🛠️  zmake installer - A Modern makepkg/make Replacement"
    echo
    
    # Parse command line arguments
    local install_method="source"
    local force_install=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --method=*)
                install_method="${1#*=}"
                shift
                ;;
            --aur)
                install_method="aur"
                shift
                ;;
            --source)
                install_method="source"
                shift
                ;;
            --force)
                force_install=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --source     Install from source (default)"
                echo "  --aur        Install from AUR"
                echo "  --force      Force reinstall even if already installed"
                echo "  --help       Show this help message"
                echo
                echo "Examples:"
                echo "  curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash"
                echo "  curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash -s -- --aur"
                exit 0
                ;;
            *)
                warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Check if zmake is already installed
    if command -v zmake &> /dev/null && [[ "$force_install" != true ]]; then
        local current_version=$(zmake version 2>/dev/null | head -n1 || echo "unknown")
        warning "zmake is already installed: $current_version"
        echo "Use --force to reinstall or run 'zmake version' to check your installation"
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    # Install zmake
    install_zmake "$install_method"
    
    # Verify installation
    info "Verifying installation..."
    if command -v zmake &> /dev/null; then
        local version=$(zmake version 2>/dev/null | head -n1 || echo "unknown")
        success "Installation successful! $version"
        echo
        info "🎉 zmake is now ready to use!"
        echo
        echo "Try these commands to get started:"
        echo "  zmake help                    # Show help"
        echo "  zmake init                    # Initialize a PKGBUILD workspace"
        echo "  zmake detect                  # Auto-detect project type"
        echo "  zmake compile --release       # Compile native project"
        echo
        echo "📚 Documentation: /usr/local/share/doc/zmake/"
        echo "🔗 Repository: https://github.com/ghostkellz/zmake"
    else
        error "Installation failed - zmake command not found"
    fi
}

# Handle script interruption
trap 'error "Installation interrupted"' INT TERM

# Run main function with all arguments
main "$@"