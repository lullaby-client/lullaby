const std = @import("std");
const java = @import("../java.zig");
const jni = @import("JNI");
const cjni = jni.cjni;

const SysMappings = struct {
    pub const System = struct {
        pub const name = "java/lang/System";
        pub const methods = struct {
            pub const currentTimeMillis = "currentTimeMillis";
        };
    };
};

const M = java.MappingSystem(SysMappings);

var last_log_time: i64 = 0;

pub fn init(ctx: anytype) !void {
    const log = std.log.scoped(.clock_mod);
    log.info("Clock Module Initialized.", .{});
    _ = ctx;
}

pub fn tick(ctx: anytype) void {
    const field_name = comptime std.meta.fieldNames(@TypeOf(ctx.env))[0];
    const raw_in_wrapper = @field(ctx.env, field_name);

    const raw_env = @as(*cjni.JNIEnv, @ptrCast(raw_in_wrapper));

    const time = M.callStatic(raw_env, "System", "currentTimeMillis", "()J", .{}) catch return;

    if (time - last_log_time > 5000) {
        const log = std.log.scoped(.clock_mod);
        log.info("Current JVM Time: {}", .{time});
        last_log_time = time;
    }
}
