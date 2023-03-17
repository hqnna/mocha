const std = @import("std");
const Value = @import("lang/types.zig").Value;
const tokenizer = @import("lang/tokenizer.zig");

pub fn typeToValue(
    comptime T: type,
    allocator: std.mem.Allocator,
    value: Value,
) !T {
    // zig fmt: off
    return switch (@typeInfo(T)) {
        .Struct => try value.object.deserialize(T, allocator),
        .Pointer => |p| if (p.child == u8) value.string else value.array.deserialize(p.child, allocator),
        .Optional => |opt| if (std.meta.activeTag(value) == .nil)
            null else try typeToValue(opt.child, value),
        .Float => value.float,
        .Bool => value.boolean,
        .Int => value.int,
        else => unreachable,
        // zig fmt: on
    };
}

pub fn testTokenizer(
    t: *tokenizer.Tokenizer,
    kind: tokenizer.Token,
    value: ?[]const u8,
) !void {
    const token = (try t.next()) orelse return error.EndOfStream;
    if (value) |v| try std.testing.expectEqualStrings(v, token.text);
    try std.testing.expectEqual(kind, token.type);
}
