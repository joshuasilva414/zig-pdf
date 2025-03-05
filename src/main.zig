const std = @import("std");
const pdflib = @import("lib/pdf.zig");
const PDFReader = pdflib.PDFReader;
const PDF = pdflib.PDF;

pub fn main() !void {
    const file = std.fs.cwd().openFile("data/test.pdf", .{}) catch |err| {
        std.debug.print("Unable to open file: {s}\n", .{@errorName(err)});
        return err;
    };
    defer file.close();

    const allocator = std.heap.page_allocator;
    const pdfReader = try PDFReader.init("data/test.pdf", allocator);
    const pdf = try pdfReader.read();
    std.debug.print("Read {s} from file\n", .{pdf.version});
}
