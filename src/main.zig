const std = @import("std");

pub const Parser = @import("lang/parser.zig");
pub usingnamespace @import("lang/types.zig");

comptime {
    std.testing.refAllDeclsRecursive(Parser);
}
