const std = @import("std");
const toklib = @import("tokens.zig");
const TokenType = toklib.TokenType;
const Token = toklib.Token;

pub const PDF = struct {
    version: []u8,
    tokens: toklib.Tokens,
};

pub const PDFReader = struct {
    allocator: std.mem.Allocator,
    file: *std.fs.File,
    fileReader: std.fs.File.Reader,

    pub fn init(filename: []const u8, allocator: std.mem.Allocator) !PDFReader {
        var file = try std.fs.cwd().openFile(filename, .{});
        return PDFReader{
            .allocator = allocator,
            .fileReader = file.reader(),
            .file = &file,
        };
    }

    pub fn deinit(self: *PDFReader) void {
        self.fileReader.deinit();
        self.file.close();
    }

    pub fn read(self: PDFReader) !PDF {
        var tokens: toklib.Tokens = std.ArrayList(Token).init(self.allocator);
        var bytes: std.ArrayList(u8) = std.ArrayList(u8).init(self.allocator);
        defer bytes.deinit();
        var currentTokenType: ?TokenType = null;

        var buff: [1]u8 = undefined;

        while (true) {
            const innerBytesRead = try self.fileReader.read(&buff);
            if (innerBytesRead == 0) break;

            const innerByte = buff[0];

            switch (innerByte) {
                '%' => {
                    if (currentTokenType) |tokenType| {
                        const tok = try self.completeToken(tokenType, &bytes);
                        try tokens.append(tok);
                    }
                    currentTokenType = TokenType.Comment;
                    continue;
                },
                '\r', '\n' => {
                    // Complete current token
                    if (currentTokenType) |tokenType| {
                        const tok = try self.completeToken(tokenType, &bytes);
                        try tokens.append(tok);
                    }
                    currentTokenType = null;
                },
                //ignore whitespace
                ' ', '\t' => {
                    // If number, complete token
                    if (currentTokenType) |tokenType| {
                        const tok = try self.completeToken(tokenType, &bytes);
                        try tokens.append(tok);
                    }
                },
                '0'...'9', '+', '-', '.' => {
                    try bytes.append(innerByte);
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
                '<' => {
                    if (tokens.getLast().token_type == TokenType.LAngleBracket) {
                        var lastToken = tokens.pop();
                        lastToken.token_type = TokenType.RDoubleAngleBracket;
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
                        const tok = try self.completeToken(tokenType, &bytes);
                        try tokens.append(tok);
                    }
                    try tokens.append(Token{ .token_type = TokenType.LParen, .value = null });
                },
                ')' => {
                    if (currentTokenType) |tokenType| {
                        const tok = try self.completeToken(tokenType, &bytes);
                        try tokens.append(tok);
                    }
                    currentTokenType = null;
                },
                else => try bytes.append(innerByte),
            }
        }

        toklib.print(&tokens, null, null);

        return PDF{
            .version = tokens.items[0].value.?,
            .tokens = tokens,
        };
    }

    fn completeToken(self: *const PDFReader, tokenType: TokenType, bytes: *std.ArrayList(u8)) !Token {
        const valueCopy = try self.allocator.alloc(u8, bytes.items.len);
        std.mem.copyForwards(u8, valueCopy, bytes.items);
        bytes.clearRetainingCapacity();
        return Token{ .token_type = tokenType, .value = valueCopy };
    }
};

fn matchSymbol(symbol: []const u8, bytes: *std.ArrayList(u8)) bool {
    if (bytes.items.len < symbol.len) return false;
    return std.mem.eql(u8, bytes.items[0..symbol.len], symbol);
}
