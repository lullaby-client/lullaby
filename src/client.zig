const std = @import("std");
const win32 = @import("win32");
const windows = win32.everything;

const JNI = @import("jni.zig");

pub const GameKind = enum {
    UNKNOWN,
    VANILLA,
    FORGE,
    FABRIC,
    LUNAR,
};

pub const Client = struct {
    handle: std.os.windows.HMODULE,
    game_kind: GameKind,

    const log = std.log.scoped(.lullaby);

    pub fn init(handle: std.os.windows.HMODULE) !Client {
        return Client{
            .handle = handle,
            .game_kind = .VANILLA,
        };
    }

    pub fn deinit(self: *Client) void {
        _ = self;
    }

    pub fn run(self: *Client) !void {
        defer self.deinit();

        log.info("Lullaby running.", .{});

        while (windows.GetAsyncKeyState(@as(i32, @intFromEnum(windows.VK_END))) == 0) {
            windows.Sleep(50);
        }
    }
};

pub fn threadMain(handle: std.os.windows.HMODULE) void {
    const log = std.log.scoped(.lullaby_threadmain);

    var instance = Client.init(handle) catch |err| {
        log.err("Failed to initialize Lullaby instance: {}", .{err});
        windows.FreeLibraryAndExitThread(@ptrCast(handle), 0);
        return;
    };
    instance.run() catch |err| {
        log.err("Runtime error: {}", .{err});
    };
    log.info("Unloading Lullaby DLL...", .{});
    windows.FreeLibraryAndExitThread(@ptrCast(handle), 0);
}
