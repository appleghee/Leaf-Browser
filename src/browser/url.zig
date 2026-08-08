const std = @import("std");

pub const DEFAULT_SEARCH_URL = "https://www.bing.com/search?q=";

pub fn isLikelyUrl(input: []const u8) bool {
    if (std.mem.indexOf(u8, input, "://") != null) return true;
    if (std.mem.indexOfScalar(u8, input, ' ') != null) return false;
    if (std.mem.indexOfScalar(u8, input, '.') != null) return true;
    return std.mem.startsWith(u8, input, "localhost");
}

pub fn normalizeNavigationTarget(allocator: std.mem.Allocator, raw_input: []const u8) ![]u8 {
    const trimmed = std.mem.trim(u8, raw_input, " \t\r\n");
    if (trimmed.len == 0) return error.EmptyNavigationTarget;

    if (isLikelyUrl(trimmed)) {
        if (std.mem.indexOf(u8, trimmed, "://") != null) {
            return allocator.dupe(u8, trimmed);
        }
        return std.fmt.allocPrint(allocator, "https://{s}", .{trimmed});
    }

    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);
    try encoded.appendSlice(allocator, DEFAULT_SEARCH_URL);
    try percentEncodeQuery(allocator, &encoded, trimmed);
    return encoded.toOwnedSlice(allocator);
}

fn percentEncodeQuery(allocator: std.mem.Allocator, out: *std.ArrayList(u8), query: []const u8) !void {
    const hex = "0123456789ABCDEF";
    for (query) |byte| {
        switch (byte) {
            'A'...'Z', 'a'...'z', '0'...'9', '-', '_', '.', '~' => try out.append(allocator, byte),
            ' ' => try out.append(allocator, '+'),
            else => {
                try out.append(allocator, '%');
                try out.append(allocator, hex[byte >> 4]);
                try out.append(allocator, hex[byte & 0x0F]);
            },
        }
    }
}

test "normalize full URL" {
    const actual = try normalizeNavigationTarget(std.testing.allocator, " https://example.com/path ");
    defer std.testing.allocator.free(actual);
    try std.testing.expectEqualStrings("https://example.com/path", actual);
}

test "normalize host name" {
    const actual = try normalizeNavigationTarget(std.testing.allocator, "example.com");
    defer std.testing.allocator.free(actual);
    try std.testing.expectEqualStrings("https://example.com", actual);
}

test "normalize search query" {
    const actual = try normalizeNavigationTarget(std.testing.allocator, "zig webview2 browser");
    defer std.testing.allocator.free(actual);
    try std.testing.expectEqualStrings("https://www.bing.com/search?q=zig+webview2+browser", actual);
}
