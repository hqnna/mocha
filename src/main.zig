const std = @import("std");
const tokenizer = @import("lang/tokenizer.zig");

comptime {
    std.testing.refAllDeclsRecursive(tokenizer);
}
