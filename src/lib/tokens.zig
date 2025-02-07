const std = @import("std");

pub const TokenType = enum(u8) { Comment = '%', Number, Identifier };

pub const Tokens: type = std.ArrayList(Token);

pub const Token = struct {
    token_type: TokenType,
    value: []u8,
};

pub fn print(self: *const Tokens) void {
    for (self.items[0..5]) |token| {
        std.debug.print("{s}: {s}\n", .{ typeToString(token.token_type), token.value });
    }
}

fn typeToString(tokenType: TokenType) []const u8 {
    switch (tokenType) {
        TokenType.Comment => return "Comment",
        TokenType.Number => return "Number",
        TokenType.Identifier => return "Identifier",
    }
}
