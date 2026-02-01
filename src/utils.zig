const std = @import("std");
const jni = @import("JNI");
const win32 = @import("win32");
const GameVersions = @import("lullaby.zig").GameVersions;

fn getWindowTitle(class_name: [*:0]const u8, buffer: *[256]u8) ?[:0]u8 {
    const hwnd = win32.ui.windows_and_messaging.FindWindowA(class_name, null);
    const len = win32.ui.windows_and_messaging.GetWindowTextA(hwnd, @ptrCast(buffer), 256);

    if (len == 0) {
        return null;
    }

    return buffer[0..@intCast(len) :0];
}

pub fn getGameVersionFromWindowClass(class_name: [*:0]const u8) GameVersions {
    var buffer: [256]u8 = undefined;
    const title = getWindowTitle(class_name, &buffer) orelse return .UNKNOWN;
    if (std.mem.indexOf(u8, title, "1.8.9") != null or std.mem.indexOf(u8, title, "1.8.8") != null) {
        if (std.mem.indexOf(u8, title, "Lunar Client") != null) return .LUNAR_1_8;
        if (std.mem.indexOf(u8, title, "Forge") != null) return .FORGE_1_8;
        if (std.mem.indexOf(u8, title, "Minecraft") != null) return .VANILLA_1_8;
        if (std.mem.indexOf(u8, title, "Feather") != null) return .FEATHER_1_8;
    }

    return .UNKNOWN;
}
