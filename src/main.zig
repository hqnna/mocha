const std = @import("std");
const Parser = @import("lang/parser.zig");

comptime {
    std.testing.refAllDeclsRecursive(Parser);
}
