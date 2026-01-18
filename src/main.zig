const std = @import("std");
const lullaby = @import("lullaby.zig");
const win32 = @import("win32");
const windows = win32.everything;

pub fn DllMain(
    handle: std.os.windows.HINSTANCE,
    fdw_reason: u32,
    _: *anyopaque,
) callconv(.winapi) windows.BOOL {
    switch (fdw_reason) {
        windows.DLL_PROCESS_ATTACH => {
            _ = windows.DisableThreadLibraryCalls(@ptrCast(@alignCast(handle)));

            const thread = std.Thread.spawn(.{}, lullaby.threadMain, .{@as(std.os.windows.HMODULE, @ptrCast(handle))}) catch |err| {
                std.log.err("Failed to spawn Lullaby thread: {}", .{err});
                return 0;
            };

            thread.detach();
        },
        windows.DLL_PROCESS_DETACH => {},
        else => {},
    }

    return 1;
}
