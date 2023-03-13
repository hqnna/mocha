const testing = @import("std").testing;
const tokenizer = @import("lang/tokenizer.zig");

pub fn testTokenizer(
    t: *tokenizer.Tokenizer,
    kind: tokenizer.Token,
    value: ?[]const u8,
) !void {
    const token = (try t.next()) orelse return error.EndOfStream;
    if (value) |v| try testing.expectEqualStrings(v, token.text);
    try testing.expectEqual(kind, token.type);
}
