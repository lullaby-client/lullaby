const std = @import("std");
const httpz = @import("httpz");
const windows = @import("win32").everything;
const index = @import("web/index.zig").index;

pub const DEFAULT_PORT = 6969;

pub fn threadMain() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.log.info("Starting Web UI", .{});

    var server = try httpz.Server(void).init(allocator, .{
        .port = DEFAULT_PORT,
        .request = .{
            .max_form_count = 20,
        },
    }, {});
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.get("/", index, .{});

    std.log.info("listening http://localhost:{d}/\n", .{DEFAULT_PORT});

    try server.listen();
}
