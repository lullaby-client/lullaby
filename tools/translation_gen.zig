const std = @import("std");

const Language = enum {
    english,
    swedish,
};

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    if (args.len != 3) fatal("wrong number of arguments", .{});

    const input_language = args[1];
    const output_file_path = args[2];

    var output_file = std.fs.cwd().createFile(output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ output_file_path, @errorName(err) });
    };
    defer output_file.close();

    if (std.mem.eql(u8, input_language, "english")) {
        // TODO: generate zig code from a json file
    } else {
        fatal("unsuported language: {s}", .{input_language});
    }

    return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
