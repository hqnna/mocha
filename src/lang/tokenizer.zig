const std = @import("std");
const ptk = @import("ptk");
const Pattern = ptk.Pattern(Token);
const testTokenizer = @import("../util.zig").testTokenizer;

// zig fmt: off
pub const Token = enum {
    object_start, array_start, object_end, array_end, comment, root,
    field_op, boolean, negate, int, float, string, ident, space, nil,
    // zig fmt: on
};

pub const Tokenizer = ptk.Tokenizer(Token, &[_]Pattern{
    Pattern.create(.float, ptk.matchers.sequenceOf(.{
        ptk.matchers.decimalNumber,
        ptk.matchers.literal("."),
        ptk.matchers.decimalNumber,
        ptk.matchers.takeAnyOf("eE"),
        ptk.matchers.takeAnyOf("+-"),
        ptk.matchers.decimalNumber,
    })),
    Pattern.create(.float, ptk.matchers.sequenceOf(.{
        ptk.matchers.decimalNumber,
        ptk.matchers.literal("."),
        ptk.matchers.decimalNumber,
        ptk.matchers.takeAnyOf("eE"),
        ptk.matchers.decimalNumber,
    })),
    Pattern.create(.float, ptk.matchers.sequenceOf(.{
        ptk.matchers.decimalNumber,
        ptk.matchers.literal("."),
        ptk.matchers.decimalNumber,
    })),
    Pattern.create(.int, ptk.matchers.sequenceOf(.{
        ptk.matchers.literal("0x"),
        ptk.matchers.hexadecimalNumber,
    })),
    Pattern.create(.int, ptk.matchers.sequenceOf(.{
        ptk.matchers.literal("0b"),
        ptk.matchers.binaryNumber,
    })),
    Pattern.create(.int, ptk.matchers.sequenceOf(.{
        ptk.matchers.literal("0o"),
        ptk.matchers.octalNumber,
    })),
    Pattern.create(.int, ptk.matchers.decimalNumber),
    Pattern.create(.root, ptk.matchers.literal("@root")),
    Pattern.create(.boolean, ptk.matchers.literal("false")),
    Pattern.create(.boolean, ptk.matchers.literal("true")),
    Pattern.create(.array_start, ptk.matchers.literal("[")),
    Pattern.create(.object_start, ptk.matchers.literal("{")),
    Pattern.create(.object_end, ptk.matchers.literal("}")),
    Pattern.create(.array_end, ptk.matchers.literal("]")),
    Pattern.create(.field_op, ptk.matchers.literal(":")),
    Pattern.create(.negate, ptk.matchers.literal("-")),
    Pattern.create(.nil, ptk.matchers.literal("nil")),
    Pattern.create(.ident, ptk.matchers.identifier),
    Pattern.create(.space, ptk.matchers.whitespace),
    Pattern.create(.string, stringLiteralMatcher),
    Pattern.create(.comment, commentMatcher),
});

fn stringLiteralMatcher(str: []const u8) ?usize {
    if (!std.mem.startsWith(u8, str, "'")) return 0;

    var length: usize = 1;
    while (length < str.len) : (length += 1) switch (str[length]) {
        '\\' => length += 1,
        else => continue,
        '\'' => break,
    };

    return length + 1;
}

fn commentMatcher(str: []const u8) ?usize {
    if (!std.mem.startsWith(u8, str, "#")) return 0;

    var length: usize = 1;
    while (length < str.len) : (length += 1) switch (str[length]) {
        else => continue,
        '\n' => break,
    };

    return length;
}

test "number tokenization" {
    var tokens = Tokenizer.init(
        \\12.32 1.024e3 1.024e-3 4096 0b11000 0x20 0o60
    , null);
    try testTokenizer(&tokens, .float, "12.32");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .float, "1.024e3");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .float, "1.024e-3");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .int, "4096");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .int, "0b11000");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .int, "0x20");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .int, "0o60");
}

test "boolean tokenization" {
    var tokens = Tokenizer.init("true false", null);
    try testTokenizer(&tokens, .boolean, "true");
    try testTokenizer(&tokens, .space, null);
    try testTokenizer(&tokens, .boolean, "false");
}

test "string tokenization" {
    var tokens = Tokenizer.init("'hello world'", null);
    try testTokenizer(&tokens, .string, "'hello world'");
}

test "nil tokenization" {
    var tokens = Tokenizer.init("nil", null);
    try testTokenizer(&tokens, .nil, "nil");
}

test "identifier tokenization" {
    var tokens = Tokenizer.init("hello_world", null);
    try testTokenizer(&tokens, .ident, "hello_world");
}

test "opterator tokenization" {
    var tokens = Tokenizer.init("{}[]:@root-", null);
    try testTokenizer(&tokens, .object_start, null);
    try testTokenizer(&tokens, .object_end, null);
    try testTokenizer(&tokens, .array_start, null);
    try testTokenizer(&tokens, .array_end, null);
    try testTokenizer(&tokens, .field_op, null);
    try testTokenizer(&tokens, .root, "@root");
    try testTokenizer(&tokens, .negate, null);
}

test "comment tokenization" {
    var tokens = Tokenizer.init("# what the fuck\n", null);
    try testTokenizer(&tokens, .comment, "# what the fuck");
}
