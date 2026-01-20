const std = @import("std");

pub fn ModuleSystem(comptime ContextType: type, comptime ModulesList: anytype) type {
    return struct {
        const Self = @This();

        pub fn create() Self {
            return .{};
        }

        pub fn init(self: *Self, ctx: ContextType) !void {
            _ = self;
            comptime {
                for (ModulesList) |Mod| {
                    switch (@typeInfo(Mod)) {
                        .@"struct" => {},
                        else => @compileError("Module must be a struct: " ++ @typeName(Mod)),
                    }
                }
            }

            inline for (ModulesList) |Mod| {
                if (@hasDecl(Mod, "init")) {
                    std.log.info("Initializing module: {s}", .{@typeName(Mod)});
                    try Mod.init(ctx);
                }
            }
        }

        pub fn deinit(self: *Self, ctx: ContextType) void {
            _ = self;
            inline for (0..ModulesList.len) |i| {
                const Mod = ModulesList[ModulesList.len - 1 - i];
                if (@hasDecl(Mod, "deinit")) {
                    std.log.info("Deinitializing module: {s}", .{@typeName(Mod)});
                    Mod.deinit(ctx);
                }
            }
        }

        pub fn tick(self: *Self, ctx: ContextType) void {
            _ = self;
            inline for (ModulesList) |Mod| {
                if (@hasDecl(Mod, "tick")) {
                    Mod.tick(ctx);
                }
            }
        }

        pub fn dispatch(self: *Self, ctx: ContextType, comptime func_name: []const u8, args: anytype) void {
            _ = self;
            inline for (ModulesList) |Mod| {
                if (@hasDecl(Mod, func_name)) {
                    @call(.auto, @field(Mod, func_name), .{ctx} ++ args);
                }
            }
        }
    };
}
