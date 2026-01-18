const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mod_JNI = b.dependency("jni", .{
        .optimize = optimize,
    }).module("JNI");
    const mod_Win32 = b.dependency("win32", .{}).module("win32");
    const mod_HTTP = b.dependency("httpz", .{
        .optimize = optimize,
    }).module("httpz");
    const mod_WEBSOCKET = b.dependency("websocket", .{
        .optimize = optimize,
    }).module("websocket");
    const dep_JDK = b.dependency("openjdk", .{});
    const mod_Lua = b.dependency("zlua", .{
        .target = b.resolveTargetQuery(.{
            .os_tag = .windows,
            .cpu_arch = .x86_64,
        }),
        .optimize = optimize,
        .lang = .luau,
    }).module("zlua");

    const lullaby = b.addLibrary(.{
        .name = "lullaby",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = .windows,
                .cpu_arch = .x86_64,
            }),
            .optimize = optimize,
        }),
    });
    lullaby.root_module.addImport("JNI", mod_JNI);
    lullaby.root_module.addImport("http", mod_HTTP);
    lullaby.root_module.addImport("win32", mod_Win32);
    lullaby.root_module.addImport("websocket", mod_WEBSOCKET);
    lullaby.root_module.addImport("luau", mod_Lua);
    lullaby.root_module.addObjectFile(dep_JDK.path("lib/JVM.lib"));
    b.installArtifact(lullaby);
}
