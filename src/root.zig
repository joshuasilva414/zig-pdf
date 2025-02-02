const std = @import("std");
const std_alloc = std.heap.page_allocator;

const TokenType = enum(u8) {
    Comment = '%',
};

pub const Token = struct {
    token_type: TokenType,
    value: []u8,
};

pub const PDF = struct {
    version: []u8,
    tokens: std.ArrayList(Token),
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
        var tokens: std.ArrayList(Token) = std.ArrayList(Token).init(self.allocator);
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
                        const valueCopy = try self.allocator.alloc(u8, bytes.items.len);
                        std.mem.copyForwards(u8, valueCopy, bytes.items);
                        bytes.clearRetainingCapacity();
                        const tok = Token{ .token_type = tokenType, .value = valueCopy };
                        try tokens.append(tok);
                    }
                    currentTokenType = TokenType.Comment;
                    continue;
                },
                else => {
                    bytes.append(byte) catch |err| {
                        return err;
                    };
                },
            }
        }

        return PDF{
            .version = tokens.items[0].value,
            .tokens = tokens,
        };
    }
};

// fn isDelimiter(byte: u8, comptime delimitters) bool {
//     return std.mem.indexOf(u8, delimitters, byte) != null;
// }
