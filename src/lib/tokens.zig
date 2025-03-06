const std = @import("std");

pub const TokenType = enum { Comment, Number, Identifier, LParen, RParen, LAngleBracket, RAngleBracket, RDoubleAngleBracket, LDoubleAngleBracket, LeftBrace, RightBrace, LAngleTilda, RAngleTilda, Tilda, HexData, NameLiteral };

pub const Tokens: type = std.ArrayList(Token);

pub const Token = struct {
    token_type: TokenType,
    value: ?[]u8,
};

pub fn print(self: *const Tokens, start: ?usize, end: ?usize) void {
    for (self.items[(start orelse 0)..(end orelse self.items.len)]) |token| {
        if (token.value) |value| {
            std.debug.print("{s}: {s}\n", .{ typeToString(token.token_type), value });
        } else {
            std.debug.print("{s}\n", .{typeToString(token.token_type)});
        }
    }
}

fn typeToString(tokenType: TokenType) []const u8 {
    switch (tokenType) {
        TokenType.Comment => return "Comment",
        TokenType.Number => return "Number",
        TokenType.Identifier => return "Identifier",
        TokenType.LParen => return "LParen",
        TokenType.RParen => return "RParen",
        TokenType.LAngleBracket => return "LAngleBracket",
        TokenType.RAngleBracket => return "RAngleBracket",
        TokenType.LDoubleAngleBracket => return "LDoubleAngleBracket",
        TokenType.RDoubleAngleBracket => return "RDoubleAngleBracket",
        TokenType.LeftBrace => return "LeftBrace",
        TokenType.RightBrace => return "RightBrace",
        TokenType.LAngleTilda => return "LAngleTilda",
        TokenType.RAngleTilda => return "RAngleTilda",
        TokenType.Tilda => return "Tilda",
        TokenType.HexData => return "HexData",
        TokenType.NameLiteral => return "NameLiteral",
    }
}
