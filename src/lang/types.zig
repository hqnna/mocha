const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../util.zig");
const Core = @import("parser.zig").Core;
const parse = @import("parser.zig").parse;

pub const Error =
    error{ MissingField, DuplicateField, RootReference } ||
    std.mem.Allocator.Error ||
    std.fmt.ParseFloatError ||
    std.fmt.ParseIntError ||
    Core.Error;

pub const Value = union(enum) {
    string: [:0]const u8,
    ref: Reference,
    boolean: bool,
    object: Object,
    array: Array,
    float: f64,
    int: i64,
    nil: void,
};

pub const Field = struct {
    name: [:0]const u8,
    value: Value,
};

pub const Reference = struct {
    name: []const u8,
    child: ?*const Reference,
};

pub const Array = struct {
    items: []Value,

    pub fn deinit(array: Array, allocator: Allocator) void {
        for (array.items) |item| switch (item) {
            .object => |v| v.deinit(allocator),
            .array => |v| v.deinit(allocator),
            .string => |v| allocator.free(v),
            else => continue,
        };

        allocator.free(array.items);
    }

    pub fn deserialize(
        array: Array,
        comptime T: type,
        allocator: Allocator,
    ) Error![]T {
        var items = std.ArrayList(T).init(allocator);
        defer items.deinit();

        for (array.items) |item|
            try items.append(try util.typeToValue(T, allocator, item));
        return try items.toOwnedSlice();
    }
};

// The Root Document Object
var root: ?Object = null;

pub const Object = struct {
    fields: []Field,

    pub fn deinit(object: Object, allocator: Allocator) void {
        for (object.fields) |field| {
            allocator.free(field.name);

            switch (field.value) {
                .object => |v| v.deinit(allocator),
                .array => |v| v.deinit(allocator),
                .string => |v| allocator.free(v),
                else => continue,
            }
        }

        allocator.free(object.fields);
    }

    pub fn deserialize(
        o: Object,
        comptime T: type,
        allocator: Allocator,
    ) Error!T {
        if (root == null) root = o;
        var fields = std.EnumSet(std.meta.FieldEnum(T)).initEmpty();
        var result: T = undefined;

        inline for (@typeInfo(T).Struct.fields) |field| {
            const name = @field(std.meta.FieldEnum(T), field.name);

            const value: Value = for (o.fields) |f| {
                if (std.mem.eql(u8, field.name, f.name)) break switch (f.value) {
                    .ref => |ref| try util.deref(root.?, o, .{ .ref = ref }),
                    else => f.value,
                };
            } else return Error.MissingField;

            if (fields.contains(name)) return Error.DuplicateField;
            fields.setPresent(name, true);

            @field(result, field.name) =
                try util.typeToValue(field.type, allocator, value);
        }

        if (fields.complement().count() != 0) return Error.MissingField;
        return result;
    }
};

test "document deserialization" {
    const alloc = std.testing.allocator;
    const MAX_SIZE = std.math.maxInt(usize);
    const FILE_PATH = "docs/examples/basic.mocha";
    const example = try std.fs.cwd().readFileAlloc(alloc, FILE_PATH, MAX_SIZE);
    defer alloc.free(example);

    var document = try parse(alloc, example);
    defer document.deinit(alloc);

    const Schema = struct {
        id: i64,
        admin: bool,
        inventory: [][]const u8,
        metadata: struct {
            dank: bool,
            heck: bool,
            lol: bool,
        },
    };

    const deserialized = try document.deserialize(Schema, alloc);
    defer alloc.free(deserialized.inventory);

    try std.testing.expectEqualStrings("apple", deserialized.inventory[0]);
    try std.testing.expectEqualStrings("cake", deserialized.inventory[1]);
    try std.testing.expectEqualStrings("sword", deserialized.inventory[2]);
    try std.testing.expectEqual(false, deserialized.metadata.heck);
    try std.testing.expectEqual(true, deserialized.metadata.dank);
    try std.testing.expectEqual(false, deserialized.metadata.lol);
    try std.testing.expectEqual(@as(i64, 1024), deserialized.id);
    try std.testing.expectEqual(true, deserialized.admin);
}
