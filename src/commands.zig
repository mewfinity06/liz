const std = @import("std");
const toml = @import("libs/zig-toml/src/root.zig");

const ArrayList = std.ArrayList;

var LIZ_DIR: []const u8 = undefined;
var HOME_DIR: []const u8 = undefined;
const ZIGLANG_GIT_PATH: []const u8 = "https://github.com/ziglang/zig";
const ZIGLANG_TOML_PATH: []const u8 = "ziglang-installed-versions.toml";
const HELP_MESSAGE: []const u8 =
    \\[Usage] ./liz <command>
    \\  Command           -> Functionality
    \\  --------------------------------------------
    \\  help              -> display this help
    \\  init              -> initialize ~/.liz directory
    \\  list              -> list installed versions
    \\  switch  <arg>     -> switch to <version | branch>
    \\  install <version> -> install specific version
    \\                       | <version> uses SEMVER (i.e. "0.16.0")
    \\                       | or name ("master", "source")
    \\                       | Default: "master"
    \\  ----------------------------------------------
;

pub const BranchType = union(enum) {
    git, // source
    unstable, // nightly
    stable, // latest
};

pub const ListOfInstances = struct {
    instances: ?[]ZigInstance,
};

pub const ZigInstance = struct {
    url: []const u8,
    version: []const u8,
    hash: []const u8,

    pub fn display(self: *ZigInstance) void {
        std.debug.print("Zig {s}#{s}\n", .{ self.version, self.hash });
    }
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

    const toml_path = try std.fs.path.join(alloc, &.{
        HOME_DIR,
        LIZ_DIR,
        ZIGLANG_TOML_PATH,
    });
    defer alloc.free(toml_path);

    var parser = toml.Parser(ListOfInstances).init(alloc);
    defer parser.deinit();

    var res = try parser.parseFile(toml_path);
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

pub fn switch_version(version: ?[]const u8) !void {
    _ = version;
}

pub fn install(version: ?[]const u8) !void {
    _ = version;
}
