const std = @import("std");
const jni = @import("JNI");
const cjni = @import("JNI").cjni;
const windows = @import("win32").everything;

var main_thread: std.Thread = undefined;
var g_hModule: ?std.os.windows.HMODULE = null;

pub fn startThread(h_module: std.os.windows.HMODULE) !u8 {
    g_hModule = h_module;
    main_thread = try std.Thread.spawn(.{}, threadMain, .{});
    return 1;
}

fn threadMain() !void {
    std.log.debug("started lullaby", .{});
    var jvm_buffer: [1][*c]cjni.JavaVM = undefined;
    var vm_count: cjni.jint = 0;

    const result = cjni.JNI_GetCreatedJavaVMs(&jvm_buffer, 1, &vm_count);

    if (result == cjni.JNI_OK and vm_count > 0) {
        const jvm = jni.JavaVM.warp(jvm_buffer[0]);
        _ = jvm;
    }

    while (windows.GetAsyncKeyState(0x23) == 0) {}

    if (g_hModule != null) {
        windows.FreeLibraryAndExitThread(@ptrCast(g_hModule.?), 0);
    }
}
