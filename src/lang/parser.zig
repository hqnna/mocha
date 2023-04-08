const Parser = @This();
const std = @import("std");
const ptk = @import("ptk");
const tkn = @import("tokenizer.zig");
const types = @import("types.zig");
const Error = types.Error;

core: Core,
allocator: std.mem.Allocator,
refs: struct { items: [65535]types.Reference = undefined, next: usize = 0 },

const RuleSet = ptk.RuleSet(tkn.Token);
pub const Core = ptk.ParserCore(tkn.Tokenizer, .{ .space, .comment });

pub fn parse(allocator: std.mem.Allocator, src: []const u8) Error!types.Object {
    var t = tkn.Tokenizer.init(src, null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = allocator,
        .refs = .{},
    };

    var fields = std.ArrayList(types.Field).init(allocator);
    defer fields.deinit();

    while (true) try fields.append(p.acceptField() catch |err| switch (err) {
        error.EndOfStream => return .{ .fields = try fields.toOwnedSlice() },
        else => return err,
    });
}

fn acceptIdentifier(p: *Parser) Error![]const u8 {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    const token = try p.core.accept(RuleSet.is(.ident));
    return token.text;
}

test "identifier parsing" {
    const data = "hello_world";
    var t = tkn.Tokenizer.init(data, null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    try std.testing.expectEqualStrings(data, try p.acceptIdentifier());
}

fn unescape(allocator: std.mem.Allocator, input: []const u8) ![:0]u8 {
    var builder = std.ArrayList(u8).init(allocator);
    defer builder.deinit();

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (i + 1 < input.len and input[i] == '\\' and input[i + 1] == '\'') {
            try builder.append('\'');
            i += 1;
        } else {
            try builder.append(input[i]);
        }
    }

    try builder.append(0);
    const bytes = try builder.toOwnedSlice();
    return bytes[0 .. bytes.len - 1 :0];
}

fn acceptValue(p: *Parser) Error!types.Value {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);
    var negate = false;

    if (try p.core.peek()) |next|
        if (next.type == .ident) return p.acceptRef();

    var t = try p.core.accept(RuleSet.oneOf(.{
        .nil,     .array_start, .object_start,
        .boolean, .negate,      .int,
        .float,   .string,
    }));

    if (t.type == .negate) {
        t = try p.core.accept(RuleSet.oneOf(.{ .int, .float }));
        negate = true;
    }

    return switch (t.type) {
        .int => types.Value{ .int = switch (negate) {
            true => -(try std.fmt.parseInt(i64, t.text, 0)),
            false => try std.fmt.parseInt(i64, t.text, 0),
        } },
        .float => types.Value{ .float = switch (negate) {
            true => -(try std.fmt.parseFloat(f64, t.text)),
            false => try std.fmt.parseFloat(f64, t.text),
        } },
        .boolean => types.Value{ .boolean = std.mem.eql(u8, t.text, "true") },
        .string => types.Value{ .string = try unescape(p.allocator, t.text[1 .. t.text.len - 1]) },
        .object_start => try p.acceptObject(),
        .array_start => try p.acceptArray(),
        .nil => types.Value.nil,
        else => unreachable,
    };
}

test "value parsing" {
    var t = tkn.Tokenizer.init(
        \\true false 12.32 4096 'hi' nil
        \\0b11000 0x20 0o60 -2048 1.024e3
        \\1.024e+3 1024.0e-3 'hello \' world'
    , null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    try std.testing.expectEqual(true, (try p.acceptValue()).boolean);
    try std.testing.expectEqual(false, (try p.acceptValue()).boolean);
    try std.testing.expectEqual(@as(f64, 12.32), (try p.acceptValue()).float);
    try std.testing.expectEqual(@as(i64, 4096), (try p.acceptValue()).int);

    const string_value = (try p.acceptValue()).string;
    defer std.testing.allocator.free(string_value);

    try std.testing.expectEqualStrings("hi", string_value);
    try std.testing.expectEqual(types.Value.nil, try p.acceptValue());
    try std.testing.expectEqual(@as(i64, 0b11000), (try p.acceptValue()).int);
    try std.testing.expectEqual(@as(i64, 0x20), (try p.acceptValue()).int);
    try std.testing.expectEqual(@as(i64, 0o60), (try p.acceptValue()).int);
    try std.testing.expectEqual(@as(i64, -2048), (try p.acceptValue()).int);
    try std.testing.expectEqual(@as(f64, 1024), (try p.acceptValue()).float);
    try std.testing.expectEqual(@as(f64, 1024), (try p.acceptValue()).float);
    try std.testing.expectEqual(@as(f64, 1.024), (try p.acceptValue()).float);

    const string_value2 = (try p.acceptValue()).string;
    defer std.testing.allocator.free(string_value2);

    try std.testing.expectEqualStrings("hello ' world", string_value2);
}

fn acceptField(p: *Parser) Error!types.Field {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    const name = try p.acceptIdentifier();
    _ = try p.core.accept(RuleSet.is(.field_op));
    const value = try p.acceptValue();

    return types.Field{ .name = try p.allocator.dupeZ(u8, name), .value = value };
}

test "field parsing" {
    var t = tkn.Tokenizer.init("hello: true", null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    const field = try p.acceptField();

    defer std.testing.allocator.free(field.name);
    try std.testing.expectEqualStrings("hello", field.name);
    try std.testing.expectEqual(true, field.value.boolean);
}

fn acceptArray(p: *Parser) Error!types.Value {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    var items = std.ArrayList(types.Value).init(p.allocator);
    defer items.deinit();

    while (try p.core.peek()) |next| switch (next.type) {
        else => try items.append(try p.acceptValue()),
        .array_end => break,
    };

    _ = try p.core.accept(RuleSet.is(.array_end));

    return types.Value{ .array = .{
        .items = try items.toOwnedSlice(),
    } };
}

test "array parsing" {
    var t = tkn.Tokenizer.init("['hello' 'world']", null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    const value = try p.acceptValue();

    try std.testing.expectEqualStrings("hello", value.array.items[0].string);
    try std.testing.expectEqualStrings("world", value.array.items[1].string);
    value.array.deinit(std.testing.allocator);
}

fn acceptObject(p: *Parser) Error!types.Value {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    var fields = std.ArrayList(types.Field).init(p.allocator);
    defer fields.deinit();

    while (try p.core.peek()) |next| switch (next.type) {
        else => try fields.append(try p.acceptField()),
        .object_end => break,
    };

    _ = try p.core.accept(RuleSet.is(.object_end));

    return types.Value{ .object = .{
        .fields = try fields.toOwnedSlice(),
    } };
}

test "object parsing" {
    var t = tkn.Tokenizer.init("{hello: true}", null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    const value = try p.acceptValue();

    try std.testing.expectEqualStrings("hello", value.object.fields[0].name);
    try std.testing.expectEqual(true, value.object.fields[0].value.boolean);
    value.object.deinit(std.testing.allocator);
}

fn acceptRef(p: *Parser) Error!types.Value {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    const name = try p.core.accept(RuleSet.is(.ident));
    var current = types.Reference{ .name = name.text, .child = null };

    if (try p.core.peek()) |next| if (next.type == .ns) {
        _ = try p.core.accept(RuleSet.is(.ns));
        const value = try p.acceptRef();

        p.refs.items[p.refs.next] = value.ref;
        current.child = &p.refs.items[p.refs.next];
        p.refs.next += 1;
    };

    return types.Value{ .ref = current };
}

test "reference parsing" {
    var t = tkn.Tokenizer.init("foo::bar::baz", null);

    var p = Parser{
        .core = Core.init(&t),
        .allocator = std.testing.allocator,
        .refs = .{},
    };

    const value = try p.acceptValue();
    try std.testing.expectEqualStrings("foo", value.ref.name);
    try std.testing.expectEqualStrings("bar", value.ref.child.?.name);
    try std.testing.expectEqualStrings("baz", value.ref.child.?.child.?.name);
}
