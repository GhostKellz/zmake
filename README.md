# 🛠️ zmake - A Modern `makepkg`/`make` Replacement in Zig

![Zig v0.15](https://img.shields.io/badge/Zig-v0.15-yellow?logo=zig)

**zmake** is a lightweight and blazing fast `makepkg` + `make` hybrid tool written entirely in Zig. It is designed to replace bloated build systems for Arch Linux users and system-level developers who want full control, performance, and modern safety. It integrates seamlessly into Zig-native and AUR build workflows.

---

## 🚀 Features

* ⚡ Lightning-fast performance with Zig v0.15
* 🧱 Built-in PKGBUILD parsing and simplified AUR support
* 🔄 Declarative `zmk.toml` or `zmk.zig` format support *(planned)*
* 🧩 Plugin-like build steps for `prepare()`, `build()`, `package()`
* 📦 Artifact caching and reproducible builds
* 🧼 Clean sandboxed temp dirs for isolated builds
* 🧪 Optional integration with `zqlite` for build metadata storage

---

## 📦 Install

```bash
# Clone the repo
git clone https://github.com/ghostkellz/zmake.git
cd zmake

# Build with Zig
zig build -Drelease-fast

# Run it
./zig-out/bin/zmake --help
```

---

## 🔧 Usage

```bash
# Initialize a new build workspace\zmake init

# Build a local PKGBUILD (or zmk.toml in future)
zmake build ./PKGBUILD

# Clean build cache
zmake clean

# Package it into .pkg.tar.zst
zmake package
```

---

## 📁 Project Layout

```
zmake/
├── src/
│   ├── main.zig
│   ├── build.zig
│   └── parser.zig
├── examples/
│   └── PKGBUILD
├── zmk.zig (or zmk.toml in future)
└── build.zig
```

---

## 🔮 Roadmap

* [ ] `zmk.toml` build definition support
* [ ] Integration with `zqlite` for tracking builds
* [ ] Web-based dashboard (optional)
* [ ] Parallel task graph engine
* [ ] Docker + sandboxed mode support
* [ ] Built-in GPG signature verification

---

## 📚 License

MIT License. See `LICENSE` file.

---

## 👻 Maintained by [GhostKellz](https://github.com/ghostkellz)

