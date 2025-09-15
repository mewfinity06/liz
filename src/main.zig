const std = @import("std");
const builtin = @import("builtin");
const eql = std.mem.eql;
const commands = @import("commands.zig");

// Liz: Zig Version Manager
//
// TODO:
// - Make Liz os agnostic
// - Install specific version
// - Uninstall specific version
// - Set global version
// - Set local version
// - Use specific version to run commands (e.g. liz run <version> -- <command>)
// - Use zig-mirrors rather than ziglang.org
pub fn main() !void {
    if (builtin.os.tag != .linux) @panic("Target must be linux");

    var da = std.heap.DebugAllocator(.{}){};
    const alloc = da.allocator();
    defer _ = da.deinit();

    // Process arguments and execute commands
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len < 2) {
        try commands.help();
        return;
    }

    if (eql(u8, args[1], "help")) try commands.help();
    if (eql(u8, args[1], "init")) try commands.init(alloc);
    if (eql(u8, args[1], "list")) try commands.list(alloc);
    if (eql(u8, args[1], "switch")) try commands.switch_version(alloc, null);
    if (eql(u8, args[1], "install")) try commands.install(alloc, null);
}

pub fn is_posix_target() bool {
    return switch (builtin.target.os.tag) {
        .linux,
        .macos,
        .freebsd,
        .netbsd,
        .openbsd,
        .dragonfly,
        .solaris,
        .illumos,
        .haiku,
        .aix,
        .wasi,
        => true,
        else => false,
    };
}
