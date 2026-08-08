const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    if (builtin.os.tag != .windows) {
        std.debug.print("Leaf Browser currently targets Windows because it embeds Microsoft Edge WebView2.\n", .{});
        return;
    }

    const window = @import("platform/window.zig");
    try window.run(.{
        .title = "Leaf Browser",
        .width = 1280,
        .height = 800,
    });
}
