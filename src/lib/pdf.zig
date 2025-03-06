const std = @import("std");
const toklib = @import("tokens.zig");
const TokenType = toklib.TokenType;
const Token = toklib.Token;
const tokenize = @import("tokenizer.zig").tokenize;
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
        errdefer file.close();
        return PDFReader{
            .allocator = allocator,
            .fileReader = file.reader(),
            .file = &file,
        };
    }

    pub fn deinit(self: *PDFReader) void {
        self.fileReader.deinit();
        self.file.close();

        self.allocator.free(self.tokens);
    }

    pub fn read(self: PDFReader) !PDF {
        const tokens = try tokenize(&self.fileReader, self.allocator);

        toklib.print(&tokens, null, 10);

        return PDF{
            .version = tokens.items[0].value.?,
            .tokens = tokens,
        };
    }
};
