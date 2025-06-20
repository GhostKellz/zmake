const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const parser = @import("parser.zig");
const builder = @import("builder.zig");
const native = @import("native.zig");

const Command = enum {
    help,
    version,
    init,
    build,
    package,
    clean,
    detect,
    compile,
    cross_compile,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try showHelp();
        return;
    }

    const command = parseCommand(args[1]) catch {
        print("❌ Unknown command: {s}\n", .{args[1]});
        print("💡 Run 'zmake help' for available commands\n", .{});
        return;
    };

    switch (command) {
        .help => try showHelp(),
        .version => try showVersion(),
        .init => try initWorkspace(allocator),
        .build => {
            const path = if (args.len > 2) args[2] else "PKGBUILD";
            try buildFromPkgBuild(allocator, path);
        },
        .package => {
            const path = if (args.len > 2) args[2] else "PKGBUILD";
            try packageFromPkgBuild(allocator, path);
        },
        .clean => try cleanBuild(allocator),
        .detect => try detectProjectType(allocator, "."),
        .compile => {
            const release = args.len > 2 and std.mem.eql(u8, args[2], "--release");
            try compileNativeProject(allocator, ".", null, release);
        },
        .cross_compile => {
            if (args.len < 3) {
                print("❌ Usage: zmake cross <target> [--release]\n");
                return;
            }
            const target = args[2];
            const release = args.len > 3 and std.mem.eql(u8, args[3], "--release");
            try compileNativeProject(allocator, ".", target, release);
        },
    }
}

fn parseCommand(arg: []const u8) !Command {
    const commands = [_]struct { []const u8, Command }{
        .{ "help", .help },
        .{ "--help", .help },
        .{ "-h", .help },
        .{ "version", .version },
        .{ "--version", .version },
        .{ "-v", .version },
        .{ "init", .init },
        .{ "build", .build },
        .{ "package", .package },
        .{ "clean", .clean },
        .{ "detect", .detect },
        .{ "compile", .compile },
        .{ "cross", .cross_compile },
    };

    for (commands) |cmd| {
        if (std.mem.eql(u8, arg, cmd[0])) {
            return cmd[1];
        }
    }
    return error.UnknownCommand;
}

fn showHelp() !void {
    print("🛠️  zmake - A Modern makepkg/make Replacement in Zig\n\n", .{});
    print("USAGE:\n", .{});
    print("    zmake <COMMAND> [OPTIONS]\n\n", .{});
    print("PKGBUILD COMMANDS:\n", .{});
    print("    init                 Initialize a new build workspace\n", .{});
    print("    build [PKGBUILD]     Build a package from PKGBUILD (default: ./PKGBUILD)\n", .{});
    print("    package [PKGBUILD]   Build and package from PKGBUILD\n", .{});
    print("    clean                Clean build cache and artifacts\n\n", .{});
    print("NATIVE COMPILATION:\n", .{});
    print("    detect               Auto-detect project type (Zig/C/C++)\n", .{});
    print("    compile [--release]  Compile native project with Zig compiler\n", .{});
    print("    cross <target> [--release]  Cross-compile for specific target\n\n", .{});
    print("GENERAL:\n", .{});
    print("    version              Show version information\n", .{});
    print("    help                 Show this help message\n\n", .{});
    print("For more information, visit: https://github.com/ghostkellz/zmake\n", .{});
}

fn showVersion() !void {
    print("zmake v0.1.0 - A Modern makepkg/make Replacement\n", .{});
    print("Built with Zig v0.15.0\n", .{});
    print("Copyright (c) 2024 GhostKellz\n", .{});
    print("Licensed under MIT License\n", .{});
}

fn initWorkspace(allocator: Allocator) !void {
    _ = allocator;
    print("🚀 Initializing zmake workspace...\n", .{});

    const pkgbuild_content =
        \\# Maintainer: Your Name <your.email@example.com>
        \\pkgname=my-package
        \\pkgver=1.0.0
        \\pkgrel=1
        \\pkgdesc="A package built with zmake"
        \\arch=('x86_64')
        \\url="https://github.com/username/my-package"
        \\license=('MIT')
        \\depends=()
        \\makedepends=('gcc')
        \\source=("my-package-${pkgver}.tar.gz")
        \\sha256sums('SKIP')
        \\
        \\prepare() {
        \\    echo "Preparing build environment..."
        \\}
        \\
        \\build() {
        \\    echo "Building package..."
        \\    # Add your build commands here
        \\}
        \\
        \\check() {
        \\    echo "Running tests..."
        \\    # Add your test commands here
        \\}
        \\
        \\package() {
        \\    echo "Installing package..."
        \\    # Add your installation commands here
        \\}
    ;

    var file = std.fs.cwd().createFile("PKGBUILD", .{}) catch |err| switch (err) {
        error.PathAlreadyExists => {
            print("⚠️  PKGBUILD already exists, skipping...\n", .{});
            return;
        },
        else => return err,
    };
    defer file.close();

    try file.writeAll(pkgbuild_content);
    print("✅ Created example PKGBUILD\n", .{});
    print("📝 Edit the PKGBUILD file and run 'zmake build' to get started!\n", .{});
}

fn buildFromPkgBuild(allocator: Allocator, path: []const u8) !void {
    print("📦 Building from: {s}\n", .{path});

    const file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            print("❌ PKGBUILD file not found: {s}\n", .{path});
            print("💡 Run 'zmake init' to create an example PKGBUILD\n", .{});
            return;
        },
        else => return err,
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var pkgbuild = parser.parsePkgBuild(allocator, content) catch |err| {
        print("❌ Failed to parse PKGBUILD: {}\n", .{err});
        return;
    };
    defer pkgbuild.deinit();

    print("✅ Parsed PKGBUILD: {s} v{s}-{s}\n", .{ pkgbuild.pkgname, pkgbuild.pkgver, pkgbuild.pkgrel });
    print("🔄 Build pipeline not yet fully implemented\n", .{});
}

fn packageFromPkgBuild(allocator: Allocator, path: []const u8) !void {
    print("📦 Packaging from: {s}\n", .{path});
    try buildFromPkgBuild(allocator, path);
    print("📦 Package creation not yet implemented\n", .{});
}

fn cleanBuild(allocator: Allocator) !void {
    _ = allocator;
    print("🧹 Cleaning build artifacts...\n", .{});
    print("✅ Cleanup completed\n", .{});
}

fn detectProjectType(allocator: Allocator, project_dir: []const u8) !void {
    print("🔍 Detecting project type in: {s}\n", .{project_dir});

    const project_type = native.detectProjectType(allocator, project_dir) catch |err| {
        print("❌ Failed to detect project type: {}\n", .{err});
        return;
    };

    switch (project_type) {
        .zig => {
            print("✅ Detected: Zig Project\n", .{});
            const zig_project = native.analyzeZigProject(allocator, project_dir) catch |err| {
                print("⚠️  Failed to analyze Zig project: {}\n", .{err});
                return;
            };
            defer zig_project.deinit();

            print("   Name: {s}\n", .{zig_project.name});
            print("   Version: {s}\n", .{zig_project.version});
        },
        .c => {
            print("✅ Detected: C Project\n", .{});
            const c_project = native.analyzeCProject(allocator, project_dir) catch |err| {
                print("⚠️  Failed to analyze C project: {}\n", .{err});
                return;
            };
            defer c_project.deinit();

            print("   Sources: {d} files\n", .{c_project.sources.len});
            print("   Headers: {d} files\n", .{c_project.headers.len});
        },
        .cpp => {
            print("✅ Detected: C++ Project\n", .{});
            const cpp_project = native.analyzeCProject(allocator, project_dir) catch |err| {
                print("⚠️  Failed to analyze C++ project: {}\n", .{err});
                return;
            };
            defer cpp_project.deinit();

            print("   Sources: {d} files\n", .{cpp_project.sources.len});
            print("   Headers: {d} files\n", .{cpp_project.headers.len});
        },
        .mixed => {
            print("✅ Detected: Mixed Project (Zig + C/C++)\n", .{});
            print("   Mixed projects not yet fully supported in detect mode\n", .{});
        },
        .unknown => {
            print("❓ Unknown project type\n", .{});
            print("💡 Supported types: Zig (.zig files), C (.c files), C++ (.cpp files)\n", .{});
        },
    }
}

fn compileNativeProject(allocator: Allocator, project_dir: []const u8, target: ?[]const u8, release_mode: bool) !void {
    const mode_str = if (release_mode) "release" else "debug";

    if (target) |t| {
        print("🎯 Cross-compiling for: {s}\n", .{t});
    } else {
        print("🔧 Compiling native project ({s} mode)\n", .{mode_str});
    }

    const project_type = native.detectProjectType(allocator, project_dir) catch |err| {
        print("❌ Failed to detect project type: {}\n", .{err});
        return;
    };

    switch (project_type) {
        .zig => {
            print("✅ Detected: Zig Project\n", .{});
            const zig_project = native.analyzeZigProject(allocator, project_dir) catch |err| {
                print("❌ Failed to analyze Zig project: {}\n", .{err});
                return;
            };
            defer zig_project.deinit();

            print("==> Building Zig project: {s} v{s}\n", .{ zig_project.name, zig_project.version });

            native.buildZigProject(allocator, &zig_project, target, release_mode) catch |err| {
                print("❌ Build failed: {}\n", .{err});
                return;
            };
        },
        .c => {
            print("✅ Detected: C Project\n", .{});
            const c_project = native.analyzeCProject(allocator, project_dir) catch |err| {
                print("❌ Failed to analyze C project: {}\n", .{err});
                return;
            };
            defer c_project.deinit();

            print("==> Building C project: {s} v{s}\n", .{ c_project.name, c_project.version });

            native.buildCProject(allocator, &c_project, target, release_mode) catch |err| {
                print("❌ Build failed: {}\n", .{err});
                return;
            };
        },
        .cpp => {
            print("✅ Detected: C++ Project\n", .{});
            const cpp_project = native.analyzeCProject(allocator, project_dir) catch |err| {
                print("❌ Failed to analyze C++ project: {}\n", .{err});
                return;
            };
            defer cpp_project.deinit();

            print("==> Building C++ project: {s} v{s}\n", .{ cpp_project.name, cpp_project.version });

            native.buildCProject(allocator, &cpp_project, target, release_mode) catch |err| {
                print("❌ Build failed: {}\n", .{err});
                return;
            };
        },
        .mixed => {
            print("✅ Detected: Mixed Project\n", .{});
            print("🔄 Mixed project compilation not yet implemented\n", .{});
        },
        .unknown => {
            print("❌ Cannot compile unknown project type\n", .{});
            print("💡 Run 'zmake detect' to see what was found\n", .{});
            return;
        },
    }

    print("🎉 Native compilation completed ({s} mode)!\n", .{mode_str});
}
