pub const Value = union(enum) {
    string: []const u8,
    boolean: bool,
    number: f64,
    nil: void,
};

pub const Field = struct {
    name: []const u8,
    value: Value,
};
