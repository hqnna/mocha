const std = @import("std");
const tokenizer = @import("lang/tokenizer.zig");
const Parser = @import("lang/parser.zig");

comptime {
    std.testing.refAllDeclsRecursive(tokenizer);
    std.testing.refAllDeclsRecursive(Parser);
}

test "parse a complete example" {
    const data = try std.fs.cwd().readFileAlloc(
        std.testing.allocator,
        "examples/rke.mocha",
        std.math.maxInt(usize),
    );

    var fields = try Parser.parse(std.testing.allocator, data);
    fields[6].value.object.deinit(std.testing.allocator);
    fields[5].value.array.deinit(std.testing.allocator);
    std.testing.allocator.free(fields);
    std.testing.allocator.free(data);
}
