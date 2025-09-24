const std = @import("std");
const base = @import("base.zig");
const windows = @import("win32").everything;

pub fn fancyLogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const ansi_reset = "\x1b[0m";
    const ansi_red = "\x1b[31m";
    const ansi_yellow = "\x1b[33m";
    const ansi_green = "\x1b[32m";
    const ansi_cyan = "\x1b[36m";

    const color = switch (level) {
        .err => ansi_red,
        .warn => ansi_yellow,
        .info => ansi_cyan,
        .debug => ansi_green,
    };

    const level_str = switch (level) {
        .err => "ERROR",
        .warn => "WARN ",
        .info => "INFO ",
        .debug => "DEBUG",
    };

    // Get time (best effort)
    var buf: [64]u8 = undefined;
    const timestamp = blk: {
        break :blk std.fmt.bufPrint(&buf, "{d}", .{std.time.timestamp()}) catch "????";
    };

    // Compose the prefix
    const prefix = std.fmt.bufPrint(&buf, "{s}[{s}][{s}]{s} ", .{ color, level_str, @tagName(scope), ansi_reset }) catch "??? ";

    // Print the prefix, timestamp, and formatted message
    std.debug.print("{s}{s} | ", .{ prefix, timestamp });
    std.debug.print(format, args);
    std.debug.print("\n", .{});
}

pub const std_options: std.Options = .{
    .logFn = fancyLogFn,
};

pub fn DllMain(
    h_module: std.os.windows.HINSTANCE,
    fdw_reason: u32,
    _: *anyopaque,
) callconv(.winapi) std.os.windows.BOOL {
    switch (fdw_reason) {
        windows.DLL_PROCESS_ATTACH => {
            _ = windows.DisableThreadLibraryCalls(@ptrCast(@alignCast(h_module)));
            return base.startThread(@ptrCast(h_module)) catch {
                return 0;
            };
        },
        windows.DLL_PROCESS_DETACH => {},
        else => {},
    }

    return 1;
}
