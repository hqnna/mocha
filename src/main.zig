const std = @import("std");
const testing = std.testing;

pub const Parser = @import("lang/parser.zig");
pub usingnamespace @import("lang/types.zig");

comptime {
    testing.refAllDeclsRecursive(Parser);
}

test "document deserialization" {
    const alloc = testing.allocator;
    const MAX_SIZE = std.math.maxInt(usize);
    const FILE_PATH = "examples/basic.mocha";
    const example = try std.fs.cwd().readFileAlloc(alloc, FILE_PATH, MAX_SIZE);
    defer alloc.free(example);

    var document = try Parser.parse(alloc, example);
    defer document.deinit(alloc);

    const Schema = struct {
        id: i64,
        admin: bool,
        inventory: [][]const u8,
        metadata: struct {
            heck: bool,
        },
    };

    const deserialized = try document.deserialize(Schema, alloc);
    defer alloc.free(deserialized.inventory);

    try testing.expectEqualStrings("apple", deserialized.inventory[0]);
    try testing.expectEqualStrings("cake", deserialized.inventory[1]);
    try testing.expectEqualStrings("sword", deserialized.inventory[2]);
    try testing.expectEqual(false, deserialized.metadata.heck);
    try testing.expectEqual(@as(i64, 1024), deserialized.id);
    try testing.expectEqual(true, deserialized.admin);
}
