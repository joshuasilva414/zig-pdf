const std = @import("std");
const toklib = @import("tokens.zig");
const Token = toklib.Token;
const TokenType = toklib.TokenType;

pub fn tokenize(reader: *const std.fs.File.Reader, allocator: std.mem.Allocator) !toklib.Tokens {
    var tokens: toklib.Tokens = std.ArrayList(Token).init(allocator);
    var bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer bytes.deinit();
    var currentTokenType: ?TokenType = null;

    var buff: [1]u8 = undefined;

    while (true) {
        const innerBytesRead = try reader.read(&buff);
        if (innerBytesRead == 0) break;

        const innerByte = buff[0];

        switch (innerByte) {
            '%' => {
                if (currentTokenType) |tokenType| {
                    const tok = try completeToken(allocator, tokenType, &bytes);
                    try tokens.append(tok);
                }
                currentTokenType = TokenType.Comment;
                continue;
            },
            '\r', '\n' => {
                // Complete current token
                if (bytes.items.len > 0) {
                    const tok = try completeToken(allocator, currentTokenType orelse TokenType.Name, &bytes);
                    try tokens.append(tok);
                }
                currentTokenType = null;
            },
            //ignore whitespace
            ' ', '\t' => {
                // If number, complete token
                if (currentTokenType) |tokenType| {
                    const tok = try completeToken(allocator, tokenType, &bytes);
                    try tokens.append(tok);
                }
                currentTokenType = null;
            },
            '0'...'9', '+', '-', '.' => {
                try bytes.append(innerByte);
                // std.debug.print("bytes: {s}\n", .{bytes.items});
                if (currentTokenType) |tokenType| {
                    if (tokenType == TokenType.Number) {
                        _ = std.fmt.parseFloat(f64, bytes.items) catch {
                            // Not a number, must be an identifier
                            currentTokenType = TokenType.Identifier;
                        };
                    }
                } else {
                    currentTokenType = TokenType.Number;
                }
            },
            '/' => {
                if (currentTokenType) |tokenType| {
                    const tok = try completeToken(allocator, tokenType, &bytes);
                    try tokens.append(tok);
                }
                currentTokenType = TokenType.NameLiteral;
            },
            '<' => {
                if (tokens.getLast().token_type == TokenType.LAngleBracket) {
                    var lastToken = tokens.pop();
                    lastToken.token_type = TokenType.LDoubleAngleBracket;
                    try tokens.append(lastToken);
                    currentTokenType = null;
                } else {
                    try tokens.append(Token{ .token_type = TokenType.LAngleBracket, .value = null });
                    currentTokenType = null;
                }
            },
            '>' => {
                if (tokens.getLast().token_type == TokenType.RAngleBracket) {
                    var lastToken = tokens.pop();
                    lastToken.token_type = TokenType.RDoubleAngleBracket;
                    try tokens.append(lastToken);
                    currentTokenType = null;
                } else if (tokens.getLast().token_type == TokenType.Tilda) {
                    var lastToken = tokens.pop();
                    lastToken.token_type = TokenType.RAngleTilda;
                    try tokens.append(lastToken);
                    currentTokenType = null;
                } else {
                    try tokens.append(Token{ .token_type = TokenType.RAngleBracket, .value = null });
                    currentTokenType = null;
                }
            },
            '~' => {
                if (tokens.getLast().token_type == TokenType.LAngleBracket) {
                    var lastToken = tokens.pop();
                    lastToken.token_type = TokenType.LAngleTilda;
                    try tokens.append(lastToken);
                    currentTokenType = null;
                } else {
                    try tokens.append(Token{ .token_type = TokenType.Tilda, .value = null });
                    currentTokenType = null;
                }
            },
            '(' => {
                if (currentTokenType) |tokenType| {
                    const tok = try completeToken(allocator, tokenType, &bytes);
                    try tokens.append(tok);
                }
                try tokens.append(Token{ .token_type = TokenType.LParen, .value = null });
            },
            ')' => {
                if (currentTokenType) |tokenType| {
                    const tok = try completeToken(allocator, tokenType, &bytes);
                    try tokens.append(tok);
                }
                currentTokenType = null;
            },
            else => try bytes.append(innerByte),
        }
    }

    return tokens;
}

fn matchSymbol(symbol: []const u8, bytes: *std.ArrayList(u8)) bool {
    if (bytes.items.len < symbol.len) return false;
    return std.mem.eql(u8, bytes.items[0..symbol.len], symbol);
}

fn completeToken(allocator: std.mem.Allocator, tokenType: TokenType, bytes: *std.ArrayList(u8)) !Token {
    const valueCopy = try allocator.alloc(u8, bytes.items.len);
    std.mem.copyForwards(u8, valueCopy, bytes.items);
    bytes.clearRetainingCapacity();
    return Token{ .token_type = tokenType, .value = valueCopy };
}
