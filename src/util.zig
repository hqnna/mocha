const std = @import("std");
const types = @import("lang/types.zig");
const tokenizer = @import("lang/tokenizer.zig");
const Error = @import("lang/types.zig").Error;

pub fn typeToValue(
    comptime T: type,
    allocator: std.mem.Allocator,
    value: types.Value,
) Error!T {
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

pub fn deref(o: types.Object, val: types.Value) Error!types.Value {
    if (std.meta.activeTag(val) != .ref) return val;

    for (o.fields) |f| if (std.mem.eql(u8, f.name, val.ref.name)) {
        if (val.ref.child == null) return f.value;
        return deref(f.value.object, .{
            .ref = val.ref.child.?.*,
        });
    };

    return Error.MissingField;
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
