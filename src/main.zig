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
// - Self-update
// - Windows support
pub fn main() !void {
    if (!is_posix_target()) @panic("Target is not POSIX compliant.");

    var da = std.heap.DebugAllocator(.{}){};
    const allocator = da.allocator();
    defer _ = da.deinit();

    // Process arguments and execute commands
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try commands.help();
        return;
    }

    if (eql(u8, args[1], "help")) try commands.help();
    if (eql(u8, args[1], "init")) try commands.init(allocator);
    if (eql(u8, args[1], "list")) try commands.list(allocator);

    if (eql(u8, args[1], "get")) {
        var branch: commands.BranchType = .stable;
        if (args.len >= 3) {
            if (eql(u8, args[2], "git") or eql(u8, args[2], "source"))
                branch = .git
            else if (eql(u8, args[2], "unstable") or eql(u8, args[2], "nightly"))
                branch = .unstable
            else if (eql(u8, args[2], "stable") or eql(u8, args[2], "latest"))
                branch = .stable
            else
                return error.unknownBranchOption;
        }
        try commands.get(branch);
    }

    if (eql(u8, args[1], "install")) try commands.install("null");
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
