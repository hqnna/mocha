const std = @import("std");
const Parser = @import("lang/parser.zig");

comptime {
    std.testing.refAllDeclsRecursive(@This());
}

test "parse a complete example" {
    const data = try std.fs.cwd().readFileAlloc(
        std.testing.allocator,
        "examples/rke.mocha",
        std.math.maxInt(usize),
    );

    var document = try Parser.parse(std.testing.allocator, data);
    defer document.deinit(std.testing.allocator);
    defer std.testing.allocator.free(data);
}
