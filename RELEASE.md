# Release Process for zmake

This document outlines the process for creating and publishing releases of zmake.

## Version Numbering

zmake follows [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)  
- **PATCH**: Bug fixes (backward compatible)

Current version: **0.1.0** (initial release)

## Pre-Release Checklist

Before creating a release:

### 1. Code Quality
- [ ] All tests pass: `zig build test`
- [ ] Code builds successfully: `zig build -Drelease-fast`
- [ ] No compiler warnings
- [ ] Documentation is up to date

### 2. Version Updates
- [ ] Update version in `build.zig.zon`
- [ ] Update version in `PKGBUILD`
- [ ] Update version in `install.sh` and `main.zig` version output
- [ ] Update CHANGELOG.md (if we have one)

### 3. Testing
- [ ] Test installation script: `./install.sh`
- [ ] Test PKGBUILD: `makepkg -f`
- [ ] Test shell completions
- [ ] Test core functionality

### 4. Documentation
- [ ] Update README.md if needed
- [ ] Verify all documentation links work
- [ ] Check that examples are current

## Creating a Release

### 1. Prepare the Release
```bash
# Make sure you're on main branch
git checkout main
git pull origin main

# Update version numbers (see checklist above)
# Edit build.zig.zon, PKGBUILD, etc.

# Commit version changes
git add .
git commit -m "chore: bump version to v0.1.0"
```

### 2. Create and Push Tag
```bash
# Create annotated tag (recommended)
git tag -a v0.1.0 -m "Release v0.1.0

- Initial release of zmake
- PKGBUILD compatibility with parallel processing
- Native Zig/C/C++ compilation support
- AUR integration
- Multi-architecture builds
- Build caching system
- Shell completions for bash/zsh
- One-liner installer"

# Push the tag
git push origin v0.1.0

# Also push the commit
git push origin main
```

### 3. Create GitHub Release
After pushing the tag, create a release on GitHub:

1. Go to https://github.com/ghostkellz/zmake/releases
2. Click "Create a new release"
3. Select the tag you just created (v0.1.0)
4. Title: "zmake v0.1.0"
5. Description: Copy from tag message or expand with details
6. Attach any release assets if needed
7. Click "Publish release"

### 4. Update Package Checksums
After creating the GitHub release, update checksums:

```bash
# Download the release tarball
wget https://github.com/ghostkellz/zmake/archive/v0.1.0.tar.gz

# Generate SHA256
sha256sum v0.1.0.tar.gz

# Update PKGBUILD with the real checksum
# Replace 'SKIP' with the actual SHA256 hash
```

### 5. Publish to AUR (Optional)
If publishing to AUR:

1. Clone AUR repository: `git clone ssh://aur@aur.archlinux.org/zmake.git`
2. Copy updated PKGBUILD
3. Test build: `makepkg -f`
4. Update .SRCINFO: `makepkg --printsrcinfo > .SRCINFO`
5. Commit and push to AUR

## Post-Release

### 1. Announce Release
- [ ] Update project website/documentation
- [ ] Social media announcement
- [ ] Notify relevant communities (r/archlinux, etc.)

### 2. Monitor
- [ ] Watch for installation issues
- [ ] Monitor GitHub issues
- [ ] Check AUR comments/votes

## Git Tagging Best Practices

### Annotated Tags (Recommended)
```bash
# Create annotated tag with message
git tag -a v0.1.0 -m "Release message"

# View tag information
git show v0.1.0

# List all tags
git tag -l
```

### Lightweight Tags (Not Recommended for Releases)
```bash
# Creates lightweight tag (just a pointer)
git tag v0.1.0

# Less information, no message
```

### Tag Naming Convention
- Use `v` prefix: `v1.0.0`, `v1.2.3`
- Pre-releases: `v1.0.0-alpha.1`, `v1.0.0-beta.2`, `v1.0.0-rc.1`
- Development: `v1.0.0-dev.20240115`

### Pushing Tags
```bash
# Push specific tag
git push origin v0.1.0

# Push all tags
git push origin --tags

# Delete remote tag (if needed)
git push origin --delete v0.1.0
```

## Release Automation (Future)

Consider adding GitHub Actions for:
- Automated testing on tag push
- Building release binaries
- Updating AUR automatically
- Publishing to package registries

Example workflow:
```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Zig
        uses: goto-bus-stop/setup-zig@v2
      - name: Build
        run: zig build -Drelease-fast
      - name: Create Release
        uses: actions/create-release@v1
        # ... etc
```

## Hotfixes

For critical bugs in releases:

1. Create hotfix branch from tag: `git checkout -b hotfix/v0.1.1 v0.1.0`
2. Fix the issue
3. Update version to patch level: `v0.1.1`
4. Create new tag and release
5. Merge back to main: `git checkout main && git merge hotfix/v0.1.1`

## Version Examples

- `v0.1.0` - Initial release
- `v0.2.0` - Added new commands (minor)
- `v0.2.1` - Bug fixes (patch)
- `v1.0.0` - Stable API, major milestone
- `v2.0.0` - Breaking changes (major)