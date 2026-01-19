const std = @import("std");

pub const Hook = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        enable: *const fn (ctx: *anyopaque) anyerror!void,
        disable: *const fn (ctx: *anyopaque) void,
        isEnabled: *const fn (ctx: *anyopaque) bool,
    };

    pub fn from(obj: anytype) Hook {
        const Ptr = @TypeOf(obj);
        const PtrInfo = @typeInfo(Ptr);

        if (PtrInfo != .Pointer) @compileError("Hook object must be a pointer");

        const impl = struct {
            fn enable(ctx: *anyopaque) anyerror!void {
                const self: Ptr = @ptrCast(@alignCast(ctx));
                return self.enable();
            }
            fn disable(ctx: *anyopaque) void {
                const self: Ptr = @ptrCast(@alignCast(ctx));
                self.disable();
            }
            fn isEnabled(ctx: *anyopaque) bool {
                const self: Ptr = @ptrCast(@alignCast(ctx));
                return self.isEnabled();
            }
        };

        return .{
            .ptr = obj,
            .vtable = &.{
                .enable = impl.enable,
                .disable = impl.disable,
                .isEnabled = impl.isEnabled,
            },
        };
    }

    pub fn enable(self: Hook) !void {
        return self.vtable.enable(self.ptr);
    }

    pub fn disable(self: Hook) void {
        self.vtable.disable(self.ptr);
    }

    pub fn isEnabled(self: Hook) bool {
        return self.vtable.isEnabled(self.ptr);
    }
};

pub const HookManager = struct {
    hooks: std.ArrayList(Hook),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HookManager {
        return .{
            .hooks = std.ArrayList(Hook).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HookManager) void {
        self.disableAll();
        self.hooks.deinit();
    }

    pub fn register(self: *HookManager, hook: Hook) !void {
        try self.hooks.append(hook);
        try hook.enable();
    }

    pub fn disableAll(self: *HookManager) void {
        for (self.hooks.items) |hook| {
            if (hook.isEnabled()) {
                hook.disable();
            }
        }
    }
};
