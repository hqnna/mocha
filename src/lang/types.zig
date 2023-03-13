const Allocator = @import("std").mem.Allocator;

pub const Value = union(enum) {
    string: []const u8,
    boolean: bool,
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
            .array => |v| v.deinit(allocator),
            else => continue,
        };

        allocator.free(array.items);
    }
};
