const std = @import("std");
const jni = @import("JNI");
const win32 = @import("win32");
const utils = @import("utils.zig");

const cjni = jni.cjni;
const windows = win32.everything;
const ModuleSystem = @import("modules.zig").ModuleSystem;
const Clock = @import("modules/clock.zig");

const ActiveModules = .{
    Clock,
};
const SystemType = ModuleSystem(*Lullaby, ActiveModules);

pub const GameVersions = enum {
    UNKNOWN,
    VANILLA_1_8,
    FORGE_1_8,
    LUNAR_1_8,
    FEATHER_1_8,
};

pub const Lullaby = struct {
    handle: std.os.windows.HMODULE,
    jvm: jni.JavaVM,
    env: jni.JNIEnv,
    sys: SystemType,
    version: GameVersions,

    const log = std.log.scoped(.lullaby);

    pub fn init(handle: std.os.windows.HMODULE) !Lullaby {
        var jvm_buf: [1][*c]cjni.JavaVM = undefined;
        var count: cjni.jint = 0;

        const res = cjni.JNI_GetCreatedJavaVMs(&jvm_buf, 1, &count);
        if (res != cjni.JNI_OK) {
            log.err("JNI_GetCreatedJavaVMs failed with code: {}", .{res});
            return error.JniInitFailed;
        }
        if (count == 0) {
            log.err("No JVM found in the target process.", .{});
            return error.NoJvmFound;
        }

        const version = utils.getGameVersionFromWindowClass("LWJGL");
        if (version == .UNKNOWN) {
            log.err("Unknown game version.", .{});
            _ = windows.MessageBoxA(
                null,
                "Unknown game version.\nSupported versions: Vanilla 1.8, Forge 1.8, Lunar 1.8, Feather 1.8\nMore soon...",
                "Lullaby",
                windows.MB_OK,
            );
            return error.UnknownGameVersion;
        }

        var jvm = jni.JavaVM.warp(jvm_buf[0]);
        var env: jni.JNIEnv = undefined;

        try jvm.attachCurrentThreadAsDaemon(&env, null);
        log.info("Attached to JVM successfully.", .{});

        return Lullaby{
            .handle = handle,
            .jvm = jvm,
            .env = env,
            .version = version,
            .sys = SystemType.create(),
        };
    }

    pub fn deinit(self: *Lullaby) void {
        self.sys.deinit(self);
        self.jvm.detachCurrentThread() catch |err| {
            log.err("Failed to detach thread from JVM: {}", .{err});
        };
        log.info("Detached from JVM.", .{});
    }

    pub fn run(self: *Lullaby) !void {
        defer self.deinit();

        try self.sys.init(self);

        log.info("Lullaby running.", .{});

        while (windows.GetAsyncKeyState(@as(i32, @intFromEnum(windows.VK_END))) == 0) {
            self.sys.tick(self);
            windows.Sleep(50);
        }
    }
};

pub fn threadMain(handle: std.os.windows.HMODULE) void {
    const log = std.log.scoped(.lullaby_thread);

    var instance = Lullaby.init(handle) catch |err| {
        log.err("Failed to initialize Lullaby: {}", .{err});
        windows.FreeLibraryAndExitThread(@ptrCast(handle), 0);
        return;
    };
    instance.run() catch |err| {
        log.err("Runtime error: {}", .{err});
    };

    log.info("Unloading Lullaby DLL...", .{});
    windows.FreeLibraryAndExitThread(@ptrCast(handle), 0);
}
