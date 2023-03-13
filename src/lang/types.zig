const Allocator = @import("std").mem.Allocator;

pub const Value = union(enum) {
    string: []const u8,
    boolean: bool,
    object: Object,
    array: Array,
    number: f64,
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
};
