# Installation & Package Management

This document covers different ways to install and manage zmake on your system.

## Quick Install (One-liner)

### Default Installation (from source)
```bash
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash
```

### AUR Installation (if available)
```bash
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash -s -- --aur
```

### Force Reinstall
```bash
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash -s -- --force
```

## Manual Installation Methods

### 1. From Source (Recommended)

**Prerequisites:**
- Zig >= 0.15.0
- Git

**Steps:**
```bash
# Clone the repository
git clone https://github.com/ghostkellz/zmake.git
cd zmake

# Build with optimizations
zig build -Drelease-fast

# Install binary
sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake

# Install documentation (optional)
sudo mkdir -p /usr/local/share/doc/zmake
sudo cp *.md /usr/local/share/doc/zmake/

# Install examples (optional)
sudo mkdir -p /usr/local/share/zmake
sudo cp -r examples /usr/local/share/zmake/
```

### 2. Using PKGBUILD (Arch Linux)

```bash
# Clone and build package
git clone https://github.com/ghostkellz/zmake.git
cd zmake

# Build package
makepkg -si

# Or build without installing
makepkg
sudo pacman -U zmake-*.pkg.tar.zst
```

### 3. From AUR (when available)

```bash
# Using yay
yay -S zmake

# Using paru
paru -S zmake

# Manual AUR installation
git clone https://aur.archlinux.org/zmake.git
cd zmake
makepkg -si
```

## Package Information

### PKGBUILD Details
- **Package name**: `zmake`
- **Version**: `0.1.0`
- **Architecture**: `x86_64`, `aarch64`
- **Dependencies**: `glibc`
- **Build dependencies**: `zig>=0.15.0`
- **Optional dependencies**:
  - `git`: for AUR package cloning
  - `tar`: for package creation
  - `zstd`: for package compression
  - `gpg`: for package signing
  - `pacman`: for dependency resolution

### Installed Files
```
/usr/bin/zmake                              # Main binary
/usr/share/doc/zmake/README.md              # Main documentation
/usr/share/doc/zmake/DOCS.md                # Detailed documentation
/usr/share/doc/zmake/COMMANDS.md            # Command reference
/usr/share/doc/zmake/INSTALL.md             # Installation guide
/usr/share/bash-completion/completions/zmake # Bash completion
/usr/share/zsh/site-functions/_zmake        # Zsh completion
/usr/share/zmake/examples/PKGBUILD          # Example PKGBUILD
/usr/share/zmake/examples/zig-project.toml  # Example Zig config
/usr/share/zmake/examples/cmake-project.toml # Example CMake config
/usr/share/zmake/examples/zig-project/      # Example Zig project
/usr/share/zmake/examples/c-project/        # Example C project
```

## Verification

After installation, verify zmake is working:

```bash
# Check version
zmake version

# Show help
zmake help

# Test project detection
cd /usr/share/zmake/examples/zig-project
zmake detect
```

Expected output:
```
zmake v0.1.0 - A Modern makepkg/make Replacement
Built with Zig v0.15.0
Copyright (c) 2024 GhostKellz
Licensed under MIT License
```

## Shell Completions

zmake includes comprehensive shell completions for both bash and zsh.

### Bash Completion
After installation, bash completion should work automatically. If not:
```bash
# Manually source completion
source /usr/share/bash-completion/completions/zmake

# Or add to ~/.bashrc
echo 'source /usr/share/bash-completion/completions/zmake' >> ~/.bashrc
```

### Zsh Completion
Zsh completion should work automatically if `/usr/share/zsh/site-functions` is in your `$fpath`. If not:
```bash
# Add to ~/.zshrc
echo 'fpath=(/usr/share/zsh/site-functions $fpath)' >> ~/.zshrc
echo 'autoload -U compinit && compinit' >> ~/.zshrc
```

### Completion Features
- **Command completion**: All zmake commands with descriptions
- **Option completion**: Command-specific flags and options
- **File completion**: PKGBUILD files, .toml configs, directories
- **Target completion**: Cross-compilation targets and target sets
- **Smart completion**: Context-aware suggestions

Try typing `zmake <TAB>` or `zmake build --<TAB>` to see completions in action!

## Updating

### From Source Installation
```bash
# Re-run the installer
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash -s -- --force

# Or manually
cd zmake
git pull
zig build -Drelease-fast
sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake
```

### From Package Installation
```bash
# Using AUR helper
yay -Syu zmake

# Manual package update
cd zmake-aur
git pull
makepkg -si
```

## Uninstallation

### Using Uninstall Script
```bash
# Download and run uninstaller
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/uninstall.sh | bash

# Force removal without confirmation
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/uninstall.sh | bash -s -- --force
```

### Manual Uninstallation

**For package installation:**
```bash
sudo pacman -Rs zmake
```

**For source installation:**
```bash
# Remove binary
sudo rm /usr/local/bin/zmake

# Remove documentation
sudo rm -rf /usr/local/share/doc/zmake

# Remove examples
sudo rm -rf /usr/local/share/zmake

# Remove cache (optional)
rm -rf ~/.cache/zmake
```

## Troubleshooting Installation

### Common Issues

#### "zig: command not found"
Install Zig from the official repositories:
```bash
sudo pacman -S zig
```

Or install a newer version from AUR:
```bash
yay -S zig-dev-bin
```

#### "Permission denied" during installation
Make sure you're not running as root and have sudo access:
```bash
# Check sudo access
sudo -v

# Run installer as regular user
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash
```

#### "Build failed" during compilation
Check Zig version and update if necessary:
```bash
zig version  # Should be >= 0.15.0

# Update system
sudo pacman -Syu

# Try building manually with verbose output
zig build -Drelease-fast --verbose
```

#### Installation script fails to download
Check internet connection and try alternative methods:
```bash
# Download script first
wget https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh
chmod +x install.sh
./install.sh

# Or clone repository manually
git clone https://github.com/ghostkellz/zmake.git
cd zmake
zig build -Drelease-fast
sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake
```

### Build Dependencies

Make sure these are installed before building:
```bash
sudo pacman -S --needed base-devel zig git
```

### Platform Support

Currently supported platforms:
- **x86_64**: Full support
- **aarch64**: Full support (ARM64)
- **i686**: Not tested but should work

### Cross-Compilation

You can also cross-compile zmake for different architectures:
```bash
# For ARM64
zig build -Drelease-fast -Dtarget=aarch64-linux-gnu

# For Windows (if needed for development)
zig build -Drelease-fast -Dtarget=x86_64-windows-gnu
```

## Development Installation

For development and contributing:

```bash
# Clone with development setup
git clone https://github.com/ghostkellz/zmake.git
cd zmake

# Build in debug mode
zig build

# Run tests
zig build test

# Install development version
sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake-dev

# Create symlink for easy updates
sudo ln -sf /usr/local/bin/zmake-dev /usr/local/bin/zmake
```

This allows you to quickly rebuild and test changes without affecting a system installation.