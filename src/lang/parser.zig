const Parser = @This();
const std = @import("std");
const ptk = @import("ptk");
const tkn = @import("tokenizer.zig");
const types = @import("types.zig");

core: Core,
allocator: std.mem.Allocator,

const RuleSet = ptk.RuleSet(tkn.Token);
const Core = ptk.ParserCore(tkn.Tokenizer, .{.space});
const Error = Core.Error || std.mem.Allocator.Error || std.fmt.ParseFloatError;

pub fn init(allocator: std.mem.Allocator, t: *tkn.Tokenizer) Parser {
    return Parser{ .core = Core.init(t), .allocator = allocator };
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
    var p = init(std.testing.allocator, &t);
    try std.testing.expectEqualStrings(data, try p.acceptIdentifier());
}

fn acceptValue(p: *Parser) Error!types.Value {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    const t = try p.core.accept(RuleSet.oneOf(.{
        .boolean, .number, .string, .nil, .array_start,
    }));

    return switch (t.type) {
        .number => types.Value{ .number = try std.fmt.parseFloat(f64, t.text) },
        .boolean => types.Value{ .boolean = std.mem.eql(u8, t.text, "true") },
        .string => types.Value{ .string = t.text[1 .. t.text.len - 1] },
        .array_start => try p.acceptArray(),
        .nil => types.Value.nil,
        else => unreachable,
    };
}

test "value parsing" {
    var t = tkn.Tokenizer.init("true false 12.32 4096 'hi' nil", null);
    var p = init(std.testing.allocator, &t);

    try std.testing.expectEqual(true, (try p.acceptValue()).boolean);
    try std.testing.expectEqual(false, (try p.acceptValue()).boolean);
    try std.testing.expectEqual(@as(f64, 12.32), (try p.acceptValue()).number);
    try std.testing.expectEqual(@as(f64, 4096), (try p.acceptValue()).number);
    try std.testing.expectEqualStrings("hi", (try p.acceptValue()).string);
    try std.testing.expectEqual(types.Value.nil, try p.acceptValue());
}

fn acceptField(p: *Parser) Error!types.Field {
    const state = p.core.saveState();
    errdefer p.core.restoreState(state);

    const name = try p.acceptIdentifier();
    _ = try p.core.accept(RuleSet.is(.field_op));
    const value = try p.acceptValue();

    return types.Field{ .name = name, .value = value };
}

test "field parsing" {
    var t = tkn.Tokenizer.init("hello: true", null);
    var p = init(std.testing.allocator, &t);
    const field = try p.acceptField();

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
    var p = init(std.testing.allocator, &t);
    const value = try p.acceptValue();

    try std.testing.expectEqualStrings("hello", value.array.items[0].string);
    try std.testing.expectEqualStrings("world", value.array.items[1].string);
    value.array.deinit(std.testing.allocator);
}
