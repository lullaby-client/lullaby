const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mod_Win32 = b.dependency("win32", .{}).module("win32");

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
    lullaby.root_module.addImport("win32", mod_Win32);
    lullaby.root_module.addObjectFile(b.path("vendor/lib64/jvm.lib"));
    b.installArtifact(lullaby);
}
