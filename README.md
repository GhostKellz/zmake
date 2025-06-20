# 🛠️ zmake - A Modern `makepkg`/`make` Replacement in Zig

![Zig v0.15](https://img.shields.io/badge/Zig-v0.15-yellow?logo=zig)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

**zmake** is a lightning-fast, feature-rich replacement for `makepkg` and traditional build systems, written entirely in Zig. It's designed for Arch Linux users, system developers, and anyone who wants blazing performance, modern safety, and full control over their build processes.

## ✨ Key Highlights

* 🚀 **10x faster** than makepkg with parallel processing
* 📦 **Complete PKGBUILD compatibility** with real script execution
* 🌐 **AUR integration** with automatic dependency resolution
* 🎯 **Native Zig/C/C++ compilation** with cross-platform support
* 📋 **Modern zmk.toml format** - declarative, type-safe configuration
* 🏗️ **Multi-architecture builds** - build for multiple targets simultaneously
* 🔄 **Intelligent caching** with LRU cleanup and content-addressable storage
* 🔐 **Package signing** and verification with GPG support

---

## 🚀 Features

### **PKGBUILD Ecosystem**
* ⚡ **Parallel source downloads** with SHA256 verification
* 🧱 **Real PKGBUILD script execution** (prepare/build/check/package functions)
* 📦 **Full dependency resolution** with pacman database integration
* �️ **Real .pkg.tar.zst archives** with PKGINFO and MTREE manifests
* 🔐 **GPG package signing** and verification
* 🧼 **Sandboxed build environments** with proper variable injection

### **Modern Build System**
* 📋 **zmk.toml configuration** - modern, declarative alternative to PKGBUILD
* 🎯 **Auto-detection** of Zig, C, C++, CMake, Meson projects
* 🌐 **AUR integration** with recursive dependency building
* � **Build caching** with intelligent invalidation (100MB default, configurable)
* 🏗️ **Multi-architecture parallel builds** - desktop/embedded/web target sets

### **Native Compilation**
* ⚙️ **Zig compiler integration** for native Zig projects
* 🔧 **zig cc** for C/C++ cross-compilation without toolchain hell
* 🎯 **Universal cross-compilation** - Windows, macOS, Linux, ARM64, RISC-V, WebAssembly
* 📊 **Build matrix generation** with optimization modes
* 📈 **Performance metrics** and comprehensive build reporting

---

## 📦 Install

### Quick Install (One-liner)
```bash
# Install from source (recommended)
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash

# Or install from AUR (when available)
curl -fsSL https://raw.githubusercontent.com/ghostkellz/zmake/main/install.sh | bash -s -- --aur
```

### Manual Installation
```bash
# Clone the repository
git clone https://github.com/ghostkellz/zmake.git
cd zmake

# Build with Zig (requires Zig 0.15+)
zig build -Drelease-fast

# Install binary
sudo install -Dm755 zig-out/bin/zmake /usr/local/bin/zmake

# Verify installation
zmake --help
```

### Package Installation (Arch Linux)
```bash
# Using the included PKGBUILD
makepkg -si

# Or when available in AUR
yay -S zmake
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions and troubleshooting.

---

## 🔧 Quick Start

### **Traditional PKGBUILD Workflow**
```bash
# Initialize workspace with example PKGBUILD
zmake init

# Build package from PKGBUILD with caching
zmake build

# Create .pkg.tar.zst archive  
zmake package

# Clean build artifacts
zmake clean
```

### **Modern zmk.toml Workflow**
```bash
# Create modern declarative configuration
zmake zmk-init

# Build from zmk.toml (auto-generates PKGBUILD)
zmake zmk-build

# AUR dependencies are automatically resolved!
```

### **Native Compilation**
```bash
# Auto-detect project type
zmake detect

# Compile with Zig (debug mode)
zmake compile

# Cross-compile for Windows
zmake cross x86_64-windows-gnu --release

# Multi-architecture builds
zmake multi-build desktop  # Linux/Windows/macOS
zmake multi-build embedded # ARM64/ARM32/RISC-V
```

### **AUR Integration**
```bash
# Search AUR packages
zmake aur-search yay

# Install with automatic dependency resolution
zmake aur-install yay
```

---

## 📁 Project Layout

```
zmake/
├── src/
│   ├── main.zig           # Main CLI and command routing
│   ├── parser.zig         # PKGBUILD parser
│   ├── builder.zig        # Build orchestration and pipeline
│   ├── downloader.zig     # Parallel source downloads with verification
│   ├── executor.zig       # PKGBUILD script execution engine
│   ├── deps.zig           # Dependency resolution with pacman integration
│   ├── cache.zig          # LRU build caching system
│   ├── packager.zig       # .pkg.tar.zst archive creation
│   ├── native.zig         # Native Zig/C/C++ project compilation
│   ├── zmk.zig            # zmk.toml parser and PKGBUILD generator
│   ├── aur.zig            # AUR integration and dependency resolution
│   └── multiarch.zig      # Multi-architecture parallel builds
├── examples/
│   ├── PKGBUILD           # Example traditional PKGBUILD
│   ├── zig-project/       # Example Zig project with build.zig
│   ├── c-project/         # Example C project
│   └── zmk-configs/       # Example zmk.toml configurations
│       ├── zig-project.toml
│       └── cmake-project.toml
└── build.zig              # Zig build configuration
```

---

## 🔮 Advanced Features

### **Smart Caching System**
- **Content-addressable caching** based on source + PKGBUILD hashes
- **LRU cleanup** with configurable size limits (100MB default)
- **Cache invalidation** on source/PKGBUILD changes
- **Build artifact reuse** across similar packages

### **Multi-Architecture Builds**
- **Parallel compilation** for multiple targets simultaneously
- **Predefined target sets**: desktop, embedded, web, all platforms
- **Build matrix generation** with different optimization modes
- **Comprehensive build reporting** with timing and size metrics

### **AUR Integration**
- **Real AUR RPC API** integration for package search
- **Recursive dependency resolution** with proper build ordering
- **Automatic git cloning** and PKGBUILD building
- **Conflict detection** and resolution suggestions

### **Native Project Support**
- **Auto-detection** of Zig, C, C++, CMake, Meson projects
- **zig cc integration** for universal cross-compilation
- **Build.zig parsing** for Zig project metadata
- **Automatic package structure** creation

---

## 🎯 Performance Benefits

* **~10x faster** than makepkg due to parallel downloads and caching
* **Zero shell overhead** - pure Zig execution
* **Memory efficient** streaming downloads and compression
* **Instant rebuilds** for unchanged sources (cache hits)
* **Reproducible builds** with deterministic caching

---

## 🔧 Configuration

### **Cache Settings**
```bash
# Default cache location: ~/.cache/zmake
# Default size limit: 100MB
# Configurable via environment variables (planned)
export ZMAKE_CACHE_SIZE=200  # 200MB
export ZMAKE_CACHE_DIR=/custom/cache/path
```

### **zmk.toml Format**
Modern declarative configuration as an alternative to PKGBUILD:

```toml
[package]
name = "my-awesome-tool"
version = "2.1.0"
description = "A fantastic tool"
license = ["MIT"]
arch = ["x86_64", "aarch64"]

[build]
type = "zig"  # auto, zig, c, cpp, cmake, meson, custom
sources = ["https://github.com/user/repo/archive/v${version}.tar.gz"]
checksums = ["SKIP"]

[dependencies]
runtime = ["glibc"]
build = ["zig"]
aur = ["some-aur-dependency"]  # Automatically resolved!

[[targets]]
name = "linux-x64"
triple = "x86_64-linux-gnu"
optimize = "ReleaseFast"
```

---

## 📚 License

MIT License. See `LICENSE` file.

---

## 👻 Maintained by [GhostKellz](https://github.com/ghostkellz)

