const std = @import("std");
const client = @import("client.zig");
const win32 = @import("win32");
const windows = win32.everything;

pub fn DllMain(
    handle: std.os.windows.HINSTANCE,
    reason: u32,
    _: *anyopaque,
) callconv(.winapi) std.os.windows.BOOL {
    switch (reason) {
        windows.DLL_PROCESS_ATTACH => {
            _ = windows.DisableThreadLibraryCalls(@ptrCast(@alignCast(handle)));

            const thread = std.Thread.spawn(.{}, client.threadMain, .{@as(std.os.windows.HMODULE, @ptrCast(handle))}) catch |err| {
                std.log.err("Failed to spawn Lullaby thread: {}", .{err});
                return .FALSE;
            };

            thread.detach();
        },
        windows.DLL_PROCESS_DETACH => {},
        else => {},
    }

    return .TRUE;
}
