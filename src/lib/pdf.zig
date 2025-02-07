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
            const bytesRead = try self.fileReader.read(&buff);
            if (bytesRead == 0) break;

            const byte = buff[0];
            switch (byte) {
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
                    if (currentTokenType) |tokenType| {
                        try bytes.append(byte);
                        if (tokenType == TokenType.Number) {
                            _ = std.fmt.parseFloat(f64, bytes.items) catch {
                                // Not a number, must be an identifier
                                currentTokenType = TokenType.Identifier;
                            };
                        }
                    } else {
                        currentTokenType = TokenType.Number;
                        try bytes.append(byte);
                    }
                },

                else => try bytes.append(byte),
            }
        }

        toklib.print(&tokens);

        return PDF{
            .version = tokens.items[0].value,
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
