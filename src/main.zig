const testing = @import("std").testing;

pub const Parser = @import("lang/parser.zig");
pub usingnamespace @import("lang/types.zig");

comptime {
    testing.refAllDeclsRecursive(Parser);
}
