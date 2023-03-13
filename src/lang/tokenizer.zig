const std = @import("std");
const ptk = @import("ptk");
const util = @import("../util.zig");

// zig fmt: off
pub const Token = enum {
    object_start, array_start, object_end, array_end, field_op,
    boolean, number, string, ident, space, nil,
// zig fmt: on
};

const Pattern = ptk.Pattern(Token);

pub const Tokenizer = ptk.Tokenizer(Token, &[_]Pattern{
    Pattern.create(.number, ptk.matchers.sequenceOf(.{
        ptk.matchers.decimalNumber,
        ptk.matchers.literal("."),
        ptk.matchers.decimalNumber,
    })),
    Pattern.create(.number, ptk.matchers.decimalNumber),
    Pattern.create(.boolean, ptk.matchers.literal("false")),
    Pattern.create(.boolean, ptk.matchers.literal("true")),
    Pattern.create(.array_start, ptk.matchers.literal("[")),
    Pattern.create(.object_start, ptk.matchers.literal("{")),
    Pattern.create(.object_end, ptk.matchers.literal("}")),
    Pattern.create(.array_end, ptk.matchers.literal("]")),
    Pattern.create(.field_op, ptk.matchers.literal(":")),
    Pattern.create(.nil, ptk.matchers.literal("nil")),
    Pattern.create(.ident, ptk.matchers.identifier),
    Pattern.create(.space, ptk.matchers.whitespace),
    Pattern.create(.string, stringLiteralMatcher),
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

test "number tokenization" {
    var tokens = Tokenizer.init("12.32 4096", null);
    try util.testTokenizer(&tokens, .number, "12.32");
    try util.testTokenizer(&tokens, .space, null);
    try util.testTokenizer(&tokens, .number, "4096");
}

test "boolean tokenization" {
    var tokens = Tokenizer.init("true false", null);
    try util.testTokenizer(&tokens, .boolean, "true");
    try util.testTokenizer(&tokens, .space, null);
    try util.testTokenizer(&tokens, .boolean, "false");
}

test "string tokenization" {
    var tokens = Tokenizer.init("'hello world'", null);
    try util.testTokenizer(&tokens, .string, "'hello world'");
}

test "nil tokenization" {
    var tokens = Tokenizer.init("nil", null);
    try util.testTokenizer(&tokens, .nil, "nil");
}

test "identifier tokenization" {
    var tokens = Tokenizer.init("hello_world", null);
    try util.testTokenizer(&tokens, .ident, "hello_world");
}

test "opterator tokenization" {
    var tokens = Tokenizer.init("{}[]:", null);
    try util.testTokenizer(&tokens, .object_start, null);
    try util.testTokenizer(&tokens, .object_end, null);
    try util.testTokenizer(&tokens, .array_start, null);
    try util.testTokenizer(&tokens, .array_end, null);
    try util.testTokenizer(&tokens, .field_op, null);
}
