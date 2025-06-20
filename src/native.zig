const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const parser = @import("parser.zig");

pub const ProjectType = enum {
    zig,
    c,
    cpp,
    mixed,
    unknown,
};

pub const ZigProject = struct {
    name: []const u8,
    version: []const u8,
    description: ?[]const u8,
    targets: [][]const u8,
    dependencies: [][]const u8,
    build_zig_path: []const u8,
    src_root: []const u8,

    allocator: Allocator,

    pub fn deinit(self: *ZigProject) void {
        self.allocator.free(self.name);
        self.allocator.free(self.version);
        if (self.description) |desc| self.allocator.free(desc);
        for (self.targets) |target| self.allocator.free(target);
        self.allocator.free(self.targets);
        for (self.dependencies) |dep| self.allocator.free(dep);
        self.allocator.free(self.dependencies);
        self.allocator.free(self.build_zig_path);
        self.allocator.free(self.src_root);
    }
};

pub const CProject = struct {
    name: []const u8,
    version: []const u8,
    sources: [][]const u8,
    headers: [][]const u8,
    libraries: [][]const u8,
    cflags: [][]const u8,
    ldflags: [][]const u8,

    allocator: Allocator,

    pub fn deinit(self: *CProject) void {
        self.allocator.free(self.name);
        self.allocator.free(self.version);
        for (self.sources) |src| self.allocator.free(src);
        self.allocator.free(self.sources);
        for (self.headers) |hdr| self.allocator.free(hdr);
        self.allocator.free(self.headers);
        for (self.libraries) |lib| self.allocator.free(lib);
        self.allocator.free(self.libraries);
        for (self.cflags) |flag| self.allocator.free(flag);
        self.allocator.free(self.cflags);
        for (self.ldflags) |flag| self.allocator.free(flag);
        self.allocator.free(self.ldflags);
    }
};

pub const NativeProject = union(ProjectType) {
    zig: ZigProject,
    c: CProject,
    cpp: CProject,
    mixed: struct { zig: ZigProject, c: CProject },
    unknown: void,

    pub fn deinit(self: *NativeProject, allocator: Allocator) void {
        _ = allocator;
        switch (self.*) {
            .zig => |*proj| proj.deinit(),
            .c, .cpp => |*proj| proj.deinit(),
            .mixed => |*proj| {
                proj.zig.deinit();
                proj.c.deinit();
            },
            .unknown => {},
        }
    }
};

pub fn detectProjectType(allocator: Allocator, project_dir: []const u8) !ProjectType {
    var dir = std.fs.cwd().openDir(project_dir, .{ .iterate = true }) catch return .unknown;
    defer dir.close();

    var has_build_zig = false;
    var has_zig_files = false;
    var has_c_files = false;
    var has_cpp_files = false;
    var has_makefile = false;

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;

        const ext = std.fs.path.extension(entry.basename);
        const basename = entry.basename;

        if (std.mem.eql(u8, basename, "build.zig")) {
            has_build_zig = true;
        } else if (std.mem.eql(u8, basename, "Makefile") or std.mem.eql(u8, basename, "makefile")) {
            has_makefile = true;
        } else if (std.mem.eql(u8, ext, ".zig")) {
            has_zig_files = true;
        } else if (std.mem.eql(u8, ext, ".c")) {
            has_c_files = true;
        } else if (std.mem.eql(u8, ext, ".cpp") or std.mem.eql(u8, ext, ".cxx") or std.mem.eql(u8, ext, ".cc")) {
            has_cpp_files = true;
        }
    }

    // Determine project type based on files found
    if (has_build_zig and has_zig_files) {
        if (has_c_files or has_cpp_files) {
            return .mixed;
        }
        return .zig;
    } else if (has_c_files and has_cpp_files) {
        return .mixed; // Treat C+C++ as mixed for now
    } else if (has_cpp_files) {
        return .cpp;
    } else if (has_c_files) {
        return .c;
    }

    return .unknown;
}

pub fn analyzeZigProject(allocator: Allocator, project_dir: []const u8) !ZigProject {
    print("==> Analyzing Zig project in: {s}\n", .{project_dir});

    // Read build.zig.zon for metadata
    const zon_path = try std.fs.path.join(allocator, &[_][]const u8{ project_dir, "build.zig.zon" });
    defer allocator.free(zon_path);

    var name = try allocator.dupe(u8, "zig-project");
    var version = try allocator.dupe(u8, "0.2.0");
    const description: ?[]const u8 = null;

    if (std.fs.cwd().openFile(zon_path, .{})) |file| {
        defer file.close();
        const content = try file.readToEndAlloc(allocator, 1024 * 1024);
        defer allocator.free(content);

        // Simple parsing of build.zig.zon (could be more sophisticated)
        if (std.mem.indexOf(u8, content, ".name = .")) |start| {
            const line_start = std.mem.lastIndexOf(u8, content[0..start], "\n") orelse 0;
            const line_end = std.mem.indexOf(u8, content[start..], "\n") orelse content.len;
            const line = std.mem.trim(u8, content[line_start .. start + line_end], " \t\n");

            if (std.mem.indexOf(u8, line, ".name = .")) |name_start| {
                const name_part = line[name_start + 9 ..];
                if (std.mem.indexOf(u8, name_part, ",")) |comma| {
                    allocator.free(name);
                    name = try allocator.dupe(u8, std.mem.trim(u8, name_part[0..comma], " \t,"));
                }
            }
        }

        if (std.mem.indexOf(u8, content, ".version = \"")) |start| {
            const version_start = start + 12;
            if (std.mem.indexOf(u8, content[version_start..], "\"")) |end| {
                allocator.free(version);
                version = try allocator.dupe(u8, content[version_start .. version_start + end]);
            }
        }
    } else |_| {
        print("⚠️  No build.zig.zon found, using defaults\n", .{});
    }

    // Find source files and build targets
    var targets = ArrayList([]const u8).init(allocator);
    defer targets.deinit();

    try targets.append(try allocator.dupe(u8, "native"));

    // Check for common cross-compilation targets in build.zig
    const build_zig_path = try std.fs.path.join(allocator, &[_][]const u8{ project_dir, "build.zig" });

    return ZigProject{
        .name = name,
        .version = version,
        .description = description,
        .targets = try targets.toOwnedSlice(),
        .dependencies = &[_][]const u8{}, // TODO: Parse from build.zig.zon
        .build_zig_path = build_zig_path,
        .src_root = try std.fs.path.join(allocator, &[_][]const u8{ project_dir, "src" }),
        .allocator = allocator,
    };
}

pub fn analyzeCProject(allocator: Allocator, project_dir: []const u8) !CProject {
    print("==> Analyzing C/C++ project in: {s}\n", .{project_dir});

    var sources = ArrayList([]const u8).init(allocator);
    defer sources.deinit();

    var headers = ArrayList([]const u8).init(allocator);
    defer headers.deinit();

    // Scan for source and header files
    var dir = try std.fs.cwd().openDir(project_dir, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;

        const ext = std.fs.path.extension(entry.basename);
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ project_dir, entry.path });

        if (std.mem.eql(u8, ext, ".c") or std.mem.eql(u8, ext, ".cpp") or
            std.mem.eql(u8, ext, ".cxx") or std.mem.eql(u8, ext, ".cc"))
        {
            try sources.append(full_path);
        } else if (std.mem.eql(u8, ext, ".h") or std.mem.eql(u8, ext, ".hpp") or
            std.mem.eql(u8, ext, ".hxx"))
        {
            try headers.append(full_path);
        } else {
            allocator.free(full_path);
        }
    }

    // Default compiler flags
    var cflags = ArrayList([]const u8).init(allocator);
    defer cflags.deinit();

    try cflags.append(try allocator.dupe(u8, "-O2"));
    try cflags.append(try allocator.dupe(u8, "-Wall"));
    try cflags.append(try allocator.dupe(u8, "-Wextra"));

    var ldflags = ArrayList([]const u8).init(allocator);
    defer ldflags.deinit();

    return CProject{
        .name = try allocator.dupe(u8, std.fs.path.basename(project_dir)),
        .version = try allocator.dupe(u8, "1.0.0"),
        .sources = try sources.toOwnedSlice(),
        .headers = try headers.toOwnedSlice(),
        .libraries = &[_][]const u8{},
        .cflags = try cflags.toOwnedSlice(),
        .ldflags = try ldflags.toOwnedSlice(),
        .allocator = allocator,
    };
}

pub fn buildZigProject(allocator: Allocator, project: *const ZigProject, target: ?[]const u8, release_mode: bool) !void {
    print("==> Building Zig project: {s} v{s}\n", .{ project.name, project.version });

    var args = ArrayList([]const u8).init(allocator);
    defer args.deinit();

    try args.append("zig");
    try args.append("build");

    if (release_mode) {
        try args.append("-Drelease-fast");
    }

    if (target) |tgt| {
        const target_arg = try std.fmt.allocPrint(allocator, "-Dtarget={s}", .{tgt});
        defer allocator.free(target_arg);
        try args.append(target_arg);
    }

    // Add verbose output
    try args.append("--verbose");

    var child = std.process.Child.init(args.items, allocator);
    child.cwd = std.fs.path.dirname(project.build_zig_path);
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const result = try child.spawnAndWait();

    if (result != .Exited or result.Exited != 0) {
        print("❌ Zig build failed\n", .{});
        return error.BuildFailed;
    }

    print("✅ Zig build completed successfully\n", .{});
}

pub fn buildCProject(allocator: Allocator, project: *const CProject, target: ?[]const u8, release_mode: bool) !void {
    print("==> Building C project: {s} v{s}\n", .{ project.name, project.version });

    if (project.sources.len == 0) {
        print("❌ No source files found\n", .{});
        return error.NoSources;
    }

    var args = ArrayList([]const u8).init(allocator);
    defer args.deinit();

    // Use zig cc for cross-compilation support
    try args.append("zig");
    try args.append("cc");

    // Add compiler flags
    for (project.cflags) |flag| {
        try args.append(flag);
    }

    if (release_mode) {
        try args.append("-O3");
        try args.append("-DNDEBUG");
    } else {
        try args.append("-g");
        try args.append("-DDEBUG");
    }

    // Add target if specified
    if (target) |tgt| {
        try args.append("-target");
        try args.append(tgt);
    }

    // Add source files
    for (project.sources) |source| {
        try args.append(source);
    }

    // Add output
    try args.append("-o");
    try args.append(project.name);

    // Add linker flags
    for (project.ldflags) |flag| {
        try args.append(flag);
    }

    var child = std.process.Child.init(args.items, allocator);
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    const result = try child.spawnAndWait();

    if (result != .Exited or result.Exited != 0) {
        print("❌ C compilation failed\n", .{});
        return error.BuildFailed;
    }

    print("✅ C build completed successfully\n", .{});
}

pub fn createNativePackage(allocator: Allocator, project: *const NativeProject, output_dir: []const u8) !void {
    print("==> Creating native package...\n", .{});

    // Create package directory structure
    const pkg_name = switch (project.*) {
        .zig => |proj| proj.name,
        .c, .cpp => |proj| proj.name,
        .mixed => |proj| proj.zig.name,
        .unknown => "unknown-package",
    };

    print("==> Packaging {s}...\n", .{pkg_name});

    const bin_dir = try std.fs.path.join(allocator, &[_][]const u8{ output_dir, "usr", "bin" });
    defer allocator.free(bin_dir);

    std.fs.cwd().makePath(bin_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    // Copy binary to package directory
    const binary_name = if (std.builtin.target.os.tag == .windows)
        try std.fmt.allocPrint(allocator, "{s}.exe", .{pkg_name})
    else
        try allocator.dupe(u8, pkg_name);
    defer allocator.free(binary_name);

    const dest_binary = try std.fs.path.join(allocator, &[_][]const u8{ bin_dir, binary_name });
    defer allocator.free(dest_binary);

    // Copy the built binary
    if (std.fs.cwd().copyFile(binary_name, std.fs.cwd(), dest_binary, .{})) {
        print("✅ Packaged binary: {s}\n", .{dest_binary});
    } else |err| {
        print("❌ Failed to package binary: {}\n", .{err});
        return err;
    }

    print("✅ Native package created in: {s}\n", .{output_dir});
}
