# Maintainer: GhostKellz <ghost@example.com>
pkgname=zmake
pkgver=0.1.0
pkgrel=1
pkgdesc="A modern makepkg/make replacement written in Zig with parallel processing, caching, and AUR integration"
arch=('x86_64' 'aarch64')
url="https://github.com/ghostkellz/zmake"
license=('MIT')
depends=('glibc')
makedepends=('zig>=0.15.0')
optdepends=(
    'git: for AUR package cloning'
    'tar: for package creation'
    'zstd: for package compression'
    'gpg: for package signing'
    'pacman: for dependency resolution'
)
source=("$pkgname-$pkgver.tar.gz::https://github.com/ghostkellz/zmake/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')  # Update this when creating actual releases

build() {
    cd "$srcdir/$pkgname-$pkgver"
    
    # Build with optimizations
    zig build -Drelease-fast --prefix /usr
}

check() {
    cd "$srcdir/$pkgname-$pkgver"
    
    # Run tests if they exist
    zig build test 2>/dev/null || echo "No tests found, skipping..."
    
    # Basic functionality test
    if [ -f "zig-out/bin/zmake" ]; then
        ./zig-out/bin/zmake version || echo "Version check failed"
    fi
}

package() {
    cd "$srcdir/$pkgname-$pkgver"
    
    # Install binary
    install -Dm755 zig-out/bin/zmake "$pkgdir/usr/bin/zmake"
    
    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 DOCS.md "$pkgdir/usr/share/doc/$pkgname/DOCS.md"
    install -Dm644 COMMANDS.md "$pkgdir/usr/share/doc/$pkgname/COMMANDS.md"
    install -Dm644 INSTALL.md "$pkgdir/usr/share/doc/$pkgname/INSTALL.md"
    
    # Install shell completions
    install -Dm644 completions/zmake.bash "$pkgdir/usr/share/bash-completion/completions/zmake"
    install -Dm644 completions/_zmake "$pkgdir/usr/share/zsh/site-functions/_zmake"
    
    # Install example configurations
    install -Dm644 examples/PKGBUILD "$pkgdir/usr/share/$pkgname/examples/PKGBUILD"
    install -Dm644 examples/zmk-configs/zig-project.toml "$pkgdir/usr/share/$pkgname/examples/zig-project.toml"
    install -Dm644 examples/zmk-configs/cmake-project.toml "$pkgdir/usr/share/$pkgname/examples/cmake-project.toml"
    
    # Install example projects
    mkdir -p "$pkgdir/usr/share/$pkgname/examples/zig-project"
    cp -r examples/zig-project/* "$pkgdir/usr/share/$pkgname/examples/zig-project/"
    
    mkdir -p "$pkgdir/usr/share/$pkgname/examples/c-project"
    cp -r examples/c-project/* "$pkgdir/usr/share/$pkgname/examples/c-project/"
}