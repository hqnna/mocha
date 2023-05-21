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

fn derefObj(root: types.Object, scope: types.Object, val: types.Value) Error!types.Value {
    if (std.mem.eql(u8, val.ref.name, "@")) {
        if (val.ref.child == null) return Error.RootReference;
        return derefObj(root, root, .{ .ref = val.ref.child.?.* });
    }

    for (scope.fields) |field| if (std.mem.eql(u8, field.name, val.ref.name)) {
        if (val.ref.child == null) return switch (field.value) {
            .ref => |ref| derefObj(root, scope, .{ .ref = ref }),
            else => field.value,
        };

        return switch (field.value) {
            .array => |arr| deref(root, .{ .array = arr }, .{ .ref = val.ref.child.?.* }),
            .object => |obj| derefObj(root, obj, .{ .ref = val.ref.child.?.* }),
            else => unreachable,
        };
    };

    return Error.MissingField;
}

fn derefArray(root: types.Object, scope: types.Array, val: types.Value) Error!types.Value {
    const child = val.ref.child;
    const i = scope.items[val.ref.index.?];
    return if (child) |c| deref(root, i, .{ .ref = c.* }) else i;
}

pub fn deref(root: types.Object, scope: types.Value, val: types.Value) Error!types.Value {
    if (std.meta.activeTag(val) != .ref) return val;

    return switch (scope) {
        .object => |obj| derefObj(root, obj, val),
        .array => |arr| derefArray(root, arr, val),
        else => unreachable,
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
