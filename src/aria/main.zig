const std = @import("std");
const main = @import("thread.zig");
const windows = @import("win32").everything;

pub fn DllMain(
    h_module: std.os.windows.HINSTANCE,
    fdw_reason: u32,
    _: *anyopaque,
) callconv(.winapi) std.os.windows.BOOL {
    switch (fdw_reason) {
        windows.DLL_PROCESS_ATTACH => {
            _ = windows.DisableThreadLibraryCalls(@ptrCast(@alignCast(h_module)));
            return main.startThread(@ptrCast(h_module)) catch {
                return 0;
            };
        },
        windows.DLL_PROCESS_DETACH => {},
        else => {},
    }

    return 1;
}
