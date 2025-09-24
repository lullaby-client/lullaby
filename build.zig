const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const dep_JNI = b.dependency("jni", .{}).module("JNI");
    const dep_Win32 = b.dependency("win32", .{}).module("win32");

    const dll = b.addLibrary(.{
        .name = "lullaby",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/dll/main.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = .windows,
            }),
            .optimize = optimize,
        }),
    });
    dll.linkLibC();
    dll.addLibraryPath(b.path("extern"));
    dll.linkSystemLibrary("jvm");
    dll.root_module.addImport("JNI", dep_JNI);
    dll.root_module.addImport("win32", dep_Win32);
    b.installArtifact(dll);
}
