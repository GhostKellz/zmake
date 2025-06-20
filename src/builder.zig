const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const parser = @import("parser.zig");
const downloader = @import("downloader.zig");
const executor = @import("executor.zig");
const deps = @import("deps.zig");
const cache = @import("cache.zig");
const packager = @import("packager.zig");

pub const BuildContext = struct {
    allocator: Allocator,
    pkgbuild: parser.PkgBuild,
    pkgbuild_content: []const u8,
    build_dir: []const u8,
    src_dir: []const u8,
    pkg_dir: []const u8,
    cache: *cache.BuildCache,
    dep_resolver: *deps.DependencyResolver,

    pub fn init(allocator: Allocator, pkgbuild: parser.PkgBuild, pkgbuild_content: []const u8) !BuildContext {
        // Initialize cache (100MB default)
        const build_cache = try allocator.create(cache.BuildCache);
        build_cache.* = try cache.BuildCache.init(allocator, "~/.cache/zmake", 100);

        // Initialize dependency resolver
        const dep_resolver = try allocator.create(deps.DependencyResolver);
        dep_resolver.* = try deps.DependencyResolver.init(allocator);

        return BuildContext{
            .allocator = allocator,
            .pkgbuild = pkgbuild,
            .pkgbuild_content = try allocator.dupe(u8, pkgbuild_content),
            .build_dir = try allocator.dupe(u8, "build"),
            .src_dir = try allocator.dupe(u8, "src"),
            .pkg_dir = try allocator.dupe(u8, "pkg"),
            .cache = build_cache,
            .dep_resolver = dep_resolver,
        };
    }

    pub fn deinit(self: *BuildContext) void {
        self.cache.deinit();
        self.allocator.destroy(self.cache);
        self.dep_resolver.deinit();
        self.allocator.destroy(self.dep_resolver);
        self.allocator.free(self.pkgbuild_content);
        self.allocator.free(self.build_dir);
        self.allocator.free(self.src_dir);
        self.allocator.free(self.pkg_dir);
    }
};

pub fn prepareBuild(ctx: *BuildContext) !void {
    print("==> Preparing build environment...\n", .{});

    // Check dependencies first
    const missing_deps = try ctx.dep_resolver.checkDependencies(ctx.pkgbuild.depends);
    defer {
        for (missing_deps) |*dep| dep.deinit(ctx.allocator);
        ctx.allocator.free(missing_deps);
    }

    if (missing_deps.len > 0) {
        try ctx.dep_resolver.suggestAURPackages(missing_deps);
        return error.MissingDependencies;
    }

    // Check for conflicts
    const conflicts = try deps.checkConflicts(ctx.allocator, &[_][]const u8{}, ctx.dep_resolver);
    defer ctx.allocator.free(conflicts);

    if (conflicts.len > 0) {
        print("❌ Package conflicts detected. Please resolve manually.\n", .{});
        return error.PackageConflicts;
    }

    // Create build directories
    std.fs.cwd().makeDir(ctx.build_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    std.fs.cwd().makeDir(ctx.src_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    std.fs.cwd().makeDir(ctx.pkg_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Check cache for existing build
    const source_hash = try ctx.cache.computeSourceHash(ctx.pkgbuild.source, ctx.pkgbuild_content);
    defer ctx.allocator.free(source_hash);

    if (ctx.cache.getCachedBuild(source_hash)) |cache_path| {
        defer ctx.allocator.free(cache_path);
        print("==> Using cached build\n", .{});
        try ctx.cache.extractBuild(cache_path, ctx.src_dir);
        return;
    }

    // Download sources in parallel
    if (ctx.pkgbuild.source.len > 0) {
        const download_results = try downloader.downloadParallel(ctx.allocator, ctx.pkgbuild.source, ctx.src_dir);
        defer {
            for (download_results) |*result| result.deinit(ctx.allocator);
            ctx.allocator.free(download_results);
        }

        // Verify downloaded files
        for (download_results, 0..) |result, i| {
            if (!result.success) {
                print("❌ Download failed: {s}\n", .{result.error_msg orelse "Unknown error"});
                return error.DownloadFailed;
            }

            // Verify SHA256 if provided
            if (i < ctx.pkgbuild.sha256sums.len) {
                const hash_valid = try downloader.verifySha256(ctx.allocator, result.path, ctx.pkgbuild.sha256sums[i]);
                if (!hash_valid) {
                    print("❌ SHA256 verification failed for: {s}\n", .{result.path});
                    return error.ChecksumMismatch;
                }
                print("✅ SHA256 verified: {s}\n", .{std.fs.path.basename(result.path)});
            }
        }
    }
}

pub fn buildPackage(ctx: *BuildContext) !void {
    print("==> Building package {s}-{s}-{s}...\n", .{ ctx.pkgbuild.pkgname, ctx.pkgbuild.pkgver, ctx.pkgbuild.pkgrel });

    // Setup build environment
    var env = try executor.BuildEnvironment.init(ctx.allocator, &ctx.pkgbuild, ".");
    defer env.deinit();

    // Execute prepare() function if it exists
    var result = try executor.executePkgBuildFunction(ctx.allocator, ctx.pkgbuild_content, "prepare", &env);
    defer result.deinit(ctx.allocator);

    if (!result.success) {
        print("❌ prepare() function failed\n", .{});
        return error.PrepareFailed;
    }

    // Execute build() function
    result = try executor.executePkgBuildFunction(ctx.allocator, ctx.pkgbuild_content, "build", &env);
    defer result.deinit(ctx.allocator);

    if (!result.success) {
        print("❌ build() function failed\n", .{});
        return error.BuildFailed;
    }

    // Execute check() function if it exists (optional)
    result = try executor.executePkgBuildFunction(ctx.allocator, ctx.pkgbuild_content, "check", &env);
    defer result.deinit(ctx.allocator);

    if (!result.success) {
        print("⚠️  check() function failed, continuing anyway\n", .{});
    }

    print("✅ Build completed successfully\n", .{});

    // Cache the successful build
    const source_hash = try ctx.cache.computeSourceHash(ctx.pkgbuild.source, ctx.pkgbuild_content);
    defer ctx.allocator.free(source_hash);

    try ctx.cache.storeBuild(source_hash, ctx.src_dir);
}

pub fn packageFiles(ctx: *BuildContext) !void {
    print("==> Packaging files...\n", .{});

    // Setup build environment for packaging
    var env = try executor.BuildEnvironment.init(ctx.allocator, &ctx.pkgbuild, ".");
    defer env.deinit();

    // Execute package() function
    var result = try executor.executePkgBuildFunction(ctx.allocator, ctx.pkgbuild_content, "package", &env);
    defer result.deinit(ctx.allocator);

    if (!result.success) {
        print("❌ package() function failed\n", .{});
        return error.PackageFailed;
    }

    // Create package archive
    var pkg_archiver = packager.PackageArchiver.init(ctx.allocator);

    const pkg_name = try std.fmt.allocPrint(ctx.allocator, "{s}-{s}-{s}-{s}.pkg.tar.zst", .{ ctx.pkgbuild.pkgname, ctx.pkgbuild.pkgver, ctx.pkgbuild.pkgrel, if (ctx.pkgbuild.arch.len > 0) ctx.pkgbuild.arch[0] else "any" });
    defer ctx.allocator.free(pkg_name);

    try pkg_archiver.createPackage(&ctx.pkgbuild, ctx.pkg_dir, pkg_name);

    // Verify the package
    const is_valid = try pkg_archiver.verifyPackage(pkg_name);
    if (!is_valid) {
        return error.PackageVerificationFailed;
    }

    print("🎉 Package created successfully: {s}\n", .{pkg_name});
}

pub fn cleanBuild(allocator: Allocator) !void {
    _ = allocator;
    print("==> Cleaning build artifacts...\n", .{});

    // Remove build directories
    std.fs.cwd().deleteTree("build") catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };

    std.fs.cwd().deleteTree("src") catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };

    std.fs.cwd().deleteTree("pkg") catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };

    print("==> Clean completed\n", .{});
}
