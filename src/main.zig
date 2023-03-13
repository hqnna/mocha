const std = @import("std");
const tokenizer = @import("lang/tokenizer.zig");
const Parser = @import("lang/parser.zig");

comptime {
    std.testing.refAllDeclsRecursive(tokenizer);
    std.testing.refAllDeclsRecursive(Parser);
}
