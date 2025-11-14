const std = @import("std");

pub fn build(b: *std.Build) void {
    const lang = b.option([]const u8, "language", "language used in the client") orelse "english";
    const optimize = b.standardOptimizeOption(.{});

    const dep_JNI = b.dependency("jni", .{}).module("JNI");
    const dep_Win32 = b.dependency("win32", .{}).module("win32");

    const tool = b.addExecutable(.{
        .name = "translation_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/translation_gen.zig"),
            .target = b.graph.host,
        }),
    });

    const tool_step = b.addRunArtifact(tool);
    tool_step.addArg(lang);
    const lang_output = tool_step.addOutputFileArg("lang.zig");

    const aria = b.addLibrary(.{
        .name = "aria",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/aria/main.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = .windows,
                .cpu_arch = .x86_64,
            }),
            .optimize = optimize,
        }),
    });
    aria.root_module.addAnonymousImport("lang", .{
        .root_source_file = lang_output,
    });
    aria.linkLibC();
    aria.addLibraryPath(b.path("extern/lib"));
    aria.addIncludePath(b.path("extern/include"));
    aria.linkSystemLibrary("jvm");
    aria.linkSystemLibrary("minhook");
    aria.root_module.addImport("JNI", dep_JNI);
    aria.root_module.addImport("win32", dep_Win32);
    b.installArtifact(aria);

    const lullaby = b.addExecutable(.{
        .name = "lullaby",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lullaby/main.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = .windows,
                .cpu_arch = .x86_64,
            }),
            .optimize = optimize,
        }),
    });
    lullaby.root_module.addAnonymousImport("lang", .{
        .root_source_file = lang_output,
    });
    lullaby.root_module.addImport("win32", dep_Win32);
    b.installArtifact(lullaby);
}
