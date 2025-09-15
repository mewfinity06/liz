const std = @import("std");
const toml = @import("libs/zig-toml/src/root.zig");

pub const InstanceList = struct {
    instances: ?[]Instance,

    pub fn from_toml(alloc: std.mem.Allocator, path: []const u8) !toml.Parsed(InstanceList) {
        var parser = toml.Parser(InstanceList).init(alloc);
        defer parser.deinit();
        return try parser.parseFile(path);
    }
};

pub const Instance = struct {
    // https://ziglang.org/download/
    url: []const u8,
    // Semantic versioning: i.e. 0.16.0
    version: []const u8,
    // SHA-sum
    hash: []const u8,
    // MONTH-DAY-YEAR: i.e. JAN-01-2025
    date_added: []const u8,

    pub fn display(self: *Instance) void {
        std.debug.print("Zig {s}#{s} ({s})\n", .{ self.version, self.hash, self.date_added });
    }
};
