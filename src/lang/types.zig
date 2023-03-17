const std = @import("std");
const Allocator = std.mem.Allocator;
const util = @import("../util.zig");

pub const Value = union(enum) {
    string: []const u8,
    boolean: bool,
    object: Object,
    array: Array,
    float: f64,
    int: i64,
    nil: void,
};

pub const Field = struct {
    name: []const u8,
    value: Value,
};

pub const Array = struct {
    items: []Value,

    pub fn deinit(array: Array, allocator: Allocator) void {
        for (array.items) |item| switch (item) {
            .object => |v| v.deinit(allocator),
            .array => |v| v.deinit(allocator),
            else => continue,
        };

        allocator.free(array.items);
    }

    pub fn deserialize(
        array: Array,
        comptime T: type,
        allocator: Allocator,
    ) ![]T {
        var items = std.ArrayList(T).init(allocator);
        defer items.deinit();

        for (array.items) |item|
            try items.append(try util.typeToValue(T, allocator, item));
        return try items.toOwnedSlice();
    }
};

pub const Object = struct {
    fields: []Field,

    pub fn deinit(object: Object, allocator: Allocator) void {
        for (object.fields) |field| switch (field.value) {
            .object => |v| v.deinit(allocator),
            .array => |v| v.deinit(allocator),
            else => continue,
        };

        allocator.free(object.fields);
    }

    pub fn deserialize(o: Object, comptime T: type, allocator: Allocator) !T {
        var fields = std.EnumSet(std.meta.FieldEnum(T)).initEmpty();
        var result: T = undefined;

        inline for (@typeInfo(T).Struct.fields) |field| {
            const name = @field(std.meta.FieldEnum(T), field.name);

            const value: Value = for (o.fields) |f| {
                if (std.mem.eql(u8, field.name, f.name)) break f.value;
            } else return error.MissingField;

            if (fields.contains(name)) return error.DuplicateField;
            fields.setPresent(name, true);

            @field(result, field.name) = try util.typeToValue(field.type, allocator, value);
        }

        if (fields.complement().count() != 0) return error.MissingFields;
        return result;
    }
};
