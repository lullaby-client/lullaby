const std = @import("std");
const jni = @import("JNI");
const cjni = @import("JNI").cjni;
const windows = @import("win32").everything;

var main_thread: std.Thread = undefined;
var g_hModule: ?std.os.windows.HMODULE = null;

pub var jvm: jni.JavaVM = undefined;
pub var jenv: jni.JNIEnv = undefined;

pub fn startThread(h_module: std.os.windows.HMODULE) !u8 {
    g_hModule = h_module;
    main_thread = try std.Thread.spawn(.{}, threadMain, .{});
    return 1;
}

fn threadMain() !void {
    var jvm_buffer: [1][*c]cjni.JavaVM = undefined;
    var vm_count: cjni.jint = 0;

    const err = jni.checkError(cjni.JNI_GetCreatedJavaVMs(&jvm_buffer, 1, &vm_count));

    if (err == jni.JNIError.JNIInvalidVersion) {
        std.log.err("Invalid JNI version", .{});
    }

    jvm = jni.JavaVM.warp(jvm_buffer[0]);

    try jvm.attachCurrentThreadAsDaemon(&jenv, null);

    while (windows.GetAsyncKeyState(0x23) == 0) {}

    try jvm.detachCurrentThread();

    if (g_hModule != null) {
        windows.FreeLibraryAndExitThread(@ptrCast(g_hModule.?), 0);
    }
}
