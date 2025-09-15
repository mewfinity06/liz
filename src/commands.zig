const std = @import("std");

const toml = @import("libs/zig-toml/src/root.zig");
const datetime = @import("libs/datetime/src/datetime.zig");

const Instance = @import("instance.zig").Instance;
const InstanceList = @import("instance.zig").InstanceList;

const Child = std.process.Child;

var LIZ_DIR: []const u8 = undefined;
var HOME_DIR: []const u8 = undefined;
const ZIGLANG_GIT_PATH: []const u8 = "https://github.com/ziglang/zig.git";
const ZIGLANG_DOWNLOAD_INDEX_JSON: []const u8 = "https://ziglang.org/download/index.json";

const ZIGLANG_TOML_PATH: []const u8 = "ziglang-installed-versions.toml";
const HELP_MESSAGE: []const u8 =
    \\[Usage] ./liz <command>
    \\  Command           -> Functionality
    \\  -------------------------------------------------------------
    \\  help              -> display this help                  [completed]
    \\  init              -> initialize ~/.liz directory        [completed]
    \\  list              -> list installed versions            [completed]
    \\  switch  <arg>     -> switch to <version | branch>       [unimplemented]
    \\  install <version> -> install specific version           [unimplemented]
    \\                       | <version> uses SEMVER ("0.16.0")
    \\                       | or name ("master", "source")
    \\                       | Default: "master"
    \\  -------------------------------------------------------------
    \\  Note: Although `<version>` is defaulted to "master",
    \\        for now, the default is "source" (git install)
;

pub const BranchType = union(enum) {
    git, // source
    unstable, // nightly
    stable, // latest
};

fn read_file(alloc: std.mem.Allocator, path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const buffer = try alloc.alloc(u8, 1024 * 1024);
    _ = try file.read(buffer);

    return buffer;
}

pub fn help() !void {
    std.debug.print("{s}\n", .{HELP_MESSAGE});
}

pub fn init(alloc: std.mem.Allocator) !void {
    LIZ_DIR = std.posix.getenv("LIZ_DIRECTORY_PATH") orelse ".liz";
    HOME_DIR = std.posix.getenv("HOME") orelse @panic("Could not get $HOME");

    const final_dir_path = try std.fs.path.join(alloc, &.{ HOME_DIR, LIZ_DIR });
    defer alloc.free(final_dir_path);

    std.debug.print("Attempting to create dir: {s}\n", .{final_dir_path});
    std.fs.makeDirAbsolute(final_dir_path) catch |err| {
        switch (err) {
            error.PathAlreadyExists => std.debug.print("Dir already exists: {s}\n", .{final_dir_path}),
            else => return err,
        }
    };

    const final_file_path = try std.fs.path.join(alloc, &.{ final_dir_path, ZIGLANG_TOML_PATH });
    defer alloc.free(final_file_path);

    std.debug.print("Attempting to create file: {s}\n", .{final_file_path});
    _ = std.fs.createFileAbsolute(final_file_path, .{ .truncate = false }) catch |err| {
        switch (err) {
            error.PathAlreadyExists => std.debug.print("Path already exists: {s}", .{final_file_path}),
            else => return err,
        }
    };
}

pub fn list(alloc: std.mem.Allocator) !void {
    LIZ_DIR = std.posix.getenv("LIZ_DIRECTORY_PATH") orelse ".liz";
    HOME_DIR = std.posix.getenv("HOME") orelse @panic("Could not get $HOME");

    const path = try std.fs.path.join(alloc, &.{
        HOME_DIR,
        LIZ_DIR,
        ZIGLANG_TOML_PATH,
    });
    defer alloc.free(path);

    var res = try InstanceList.from_toml(alloc, path);
    defer res.deinit();

    if (res.value.instances) |instances| {
        std.debug.print("Installed Zig Versions ({})\n", .{instances.len});
        for (instances, 0..) |*instance, i| {
            std.debug.print("[{}] ", .{i});
            instance.display();
        }
    } else {
        std.debug.print("No installed versions\n", .{});
    }
}

pub fn switch_version(alloc: std.mem.Allocator, version: ?[]const u8) !void {
    _ = alloc;
    _ = version;
}

fn check_term(term: Child.Term) !void {
    switch (term) {
        .Exited => |code| if (code != 0) {
            std.debug.print("Exited with non-zero exit code ({})\n", .{code});
            return error.NonZeroExitCode;
        },
        else => {
            std.debug.print("Unknown term: {any}", .{term});
            return error.UnknownTerm;
        },
    }
}

fn install_git(alloc: std.mem.Allocator, path: []const u8) !void {
    // time
    const now = datetime.Date.now();
    const now_str = try now.formatIso(alloc);
    defer alloc.free(now_str);

    // TODO: Get zig version for name as well (i.e. zig-0.16.0-2025-09-14)
    //       But now we just have "zig-2025-09-14"
    const zig_new_path_name = try std.fmt.allocPrint(alloc, "", .{});

    // cd $PATH && git clone ZIGLANG_GIT_PATH zig-$TIME
    const args = try std.fmt.allocPrint(
        alloc,
        "cd {s} && git clone --depth=1 {s} {s}",
        .{ path, ZIGLANG_GIT_PATH, zig_new_path_name },
    );
    defer alloc.free(args);

    var child = Child.init(&.{ "sh", "-c", args }, alloc);
    try child.spawn();
    try check_term(try child.wait()); // self cleanup
}

pub fn install(alloc: std.mem.Allocator, version: ?[]const u8) !void {
    HOME_DIR = std.posix.getenv("HOME") orelse @panic("Could not get $HOME");
    LIZ_DIR = std.posix.getenv("LIZ_DIRECTORY_PATH") orelse ".liz";

    // Download git version
    const path = try std.fs.path.join(alloc, &.{ HOME_DIR, LIZ_DIR });
    defer alloc.free(path);

    try install_git(alloc, path);

    // Get toml
    const toml_path = try std.fs.path.join(alloc, &.{
        HOME_DIR,
        LIZ_DIR,
        ZIGLANG_TOML_PATH,
    });
    defer alloc.free(toml_path);

    var res = try InstanceList.from_toml(alloc, toml_path);
    defer res.deinit();

    _ = version;
}
