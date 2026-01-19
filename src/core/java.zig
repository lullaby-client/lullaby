const std = @import("std");
const jni = @import("JNI");
const cjni = jni.cjni;

pub fn MappingSystem(comptime Schema: type) type {
    return struct {
        const Self = @This();

        pub fn class(comptime friendly_name: []const u8) []const u8 {
            validateClass(friendly_name);
            const Entry = @field(Schema, friendly_name);
            return extractName(Entry);
        }

        pub fn field(comptime friendly_class: []const u8, comptime friendly_field: []const u8) []const u8 {
            validateClass(friendly_class);
            const Entry = @field(Schema, friendly_class);
            if (!@hasDecl(Entry, "fields")) @compileError("Class " ++ friendly_class ++ " has no fields defined.");
            const Fields = Entry.fields;
            if (!@hasDecl(Fields, friendly_field)) @compileError("Field " ++ friendly_field ++ " not found in " ++ friendly_class);
            return @field(Fields, friendly_field);
        }

        pub fn method(comptime friendly_class: []const u8, comptime friendly_method: []const u8) []const u8 {
            validateClass(friendly_class);
            const Entry = @field(Schema, friendly_class);
            if (!@hasDecl(Entry, "methods")) @compileError("Class " ++ friendly_class ++ " has no methods defined.");
            const Methods = Entry.methods;
            if (!@hasDecl(Methods, friendly_method)) @compileError("Method " ++ friendly_method ++ " not found in " ++ friendly_class);
            return @field(Methods, friendly_method);
        }

        pub fn sig(comptime signature: []const u8) []const u8 {
            return comptime blk: {
                var res: []const u8 = "";
                var i: usize = 0;
                while (i < signature.len) {
                    const c = signature[i];
                    if (c == 'L') {
                        const end = std.mem.indexOfScalarPos(u8, signature, i, ';') orelse @compileError("Invalid signature: missing ;");
                        const name = signature[i + 1 .. end];
                        if (@hasDecl(Schema, name)) {
                            res = res ++ "L" ++ class(name) ++ ";";
                        } else {
                            res = res ++ signature[i .. end + 1];
                        }
                        i = end + 1;
                    } else {
                        res = res ++ signature[i .. i + 1];
                        i += 1;
                    }
                }
                break :blk res;
            };
        }

        pub fn unobfuscate(obf_name: []const u8) ?[]const u8 {
            const decls = comptime std.meta.declarations(Schema);
            inline for (decls) |decl| {
                const c_name = decl.name;
                const obf = class(c_name);
                if (std.mem.eql(u8, obf, obf_name)) {
                    return c_name;
                }
            }
            return null;
        }

        pub fn findClass(env: *cjni.JNIEnv, comptime friendly_name: []const u8) !cjni.jclass {
            const cls_name = comptime class(friendly_name) ++ "\x00";
            const vtable = @as(*const cjni.JNINativeInterface_, @ptrCast(env.*));
            const cls = vtable.FindClass.?(env, cls_name.ptr) orelse return error.JNIFindClassFailed;
            return cls;
        }

        pub fn call(env: *cjni.JNIEnv, instance: cjni.jobject, comptime cls_name: []const u8, comptime method_name: []const u8, comptime signature: []const u8, args: anytype) !JniRetType(sig(signature)) {
            const clazz = try findClass(env, cls_name);
            const vtable = @as(*const cjni.JNINativeInterface_, @ptrCast(env.*));

            const m_name = comptime method(cls_name, method_name) ++ "\x00";
            const m_sig = comptime sig(signature) ++ "\x00";
            const mid = vtable.GetMethodID.?(env, clazz, m_name.ptr, m_sig.ptr) orelse return error.JNIGetMethodIDFailed;

            var jargs: [args.len]cjni.jvalue = undefined;
            inline for (args, 0..) |arg, i| {
                jargs[i] = toJValue(arg);
            }
            const jargs_ptr = if (args.len > 0) &jargs[0] else null;

            const ret_char = comptime getRetChar(sig(signature));
            if (ret_char == 'V') {
                vtable.CallVoidMethodA.?(env, instance, mid, jargs_ptr);
                return;
            } else if (ret_char == 'Z') {
                const val = vtable.CallBooleanMethodA.?(env, instance, mid, jargs_ptr);
                return val != 0;
            } else if (ret_char == 'I') {
                return vtable.CallIntMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'J') {
                return vtable.CallLongMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'F') {
                return vtable.CallFloatMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'D') {
                return vtable.CallDoubleMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'L' or ret_char == '[') {
                return vtable.CallObjectMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'B') {
                return vtable.CallByteMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'C') {
                return vtable.CallCharMethodA.?(env, instance, mid, jargs_ptr);
            } else if (ret_char == 'S') {
                return vtable.CallShortMethodA.?(env, instance, mid, jargs_ptr);
            }

            @compileError("Unsupported return type char: " ++ &[_]u8{ret_char});
        }

        pub fn callStatic(env: *cjni.JNIEnv, comptime cls_name: []const u8, comptime method_name: []const u8, comptime signature: []const u8, args: anytype) !JniRetType(sig(signature)) {
            const clazz = try findClass(env, cls_name);
            const vtable = @as(*const cjni.JNINativeInterface_, @ptrCast(env.*));

            const m_name = comptime method(cls_name, method_name) ++ "\x00";
            const m_sig = comptime sig(signature) ++ "\x00";
            const mid = vtable.GetStaticMethodID.?(env, clazz, m_name.ptr, m_sig.ptr) orelse return error.JNIGetStaticMethodIDFailed;

            var jargs: [args.len]cjni.jvalue = undefined;
            inline for (args, 0..) |arg, i| {
                jargs[i] = toJValue(arg);
            }
            const jargs_ptr = if (args.len > 0) &jargs[0] else null;

            const ret_char = comptime getRetChar(sig(signature));
            if (ret_char == 'V') {
                vtable.CallStaticVoidMethodA.?(env, clazz, mid, jargs_ptr);
                return;
            } else if (ret_char == 'Z') {
                const val = vtable.CallStaticBooleanMethodA.?(env, clazz, mid, jargs_ptr);
                return val != 0;
            } else if (ret_char == 'I') {
                return vtable.CallStaticIntMethodA.?(env, clazz, mid, jargs_ptr);
            } else if (ret_char == 'J') {
                return vtable.CallStaticLongMethodA.?(env, clazz, mid, jargs_ptr);
            } else if (ret_char == 'F') {
                return vtable.CallStaticFloatMethodA.?(env, clazz, mid, jargs_ptr);
            } else if (ret_char == 'D') {
                return vtable.CallStaticDoubleMethodA.?(env, clazz, mid, jargs_ptr);
            } else if (ret_char == 'L' or ret_char == '[') {
                return vtable.CallStaticObjectMethodA.?(env, clazz, mid, jargs_ptr);
            }
            @compileError("Unsupported return type char: " ++ &[_]u8{ret_char});
        }

        fn validateClass(comptime name: []const u8) void {
            if (!@hasDecl(Schema, name)) @compileError("Mapping Schema missing class: " ++ name);
        }

        fn extractName(comptime Entry: anytype) []const u8 {
            const T = @TypeOf(Entry);
            switch (@typeInfo(T)) {
                .pointer => |ptr| {
                    if (ptr.size == .slice and ptr.child == u8) return Entry;
                    if (ptr.size == .one and @typeInfo(ptr.child) == .array) {
                        if (@typeInfo(ptr.child).array.child == u8) return Entry;
                    }
                },
                .type => {
                    if (@hasDecl(Entry, "name")) return Entry.name;
                },
                .@"struct" => {
                    if (@hasDecl(Entry, "name")) return Entry.name;
                },
                else => {},
            }
            @compileError("Invalid schema entry type. Got: " ++ @typeName(T));
        }
    };
}

fn toJValue(val: anytype) cjni.jvalue {
    const T = @TypeOf(val);
    if (T == bool) return .{ .z = if (val) 1 else 0 };
    if (T == i32 or T == c_int) return .{ .i = val };
    if (T == i64 or T == c_longlong) return .{ .j = val };
    if (T == f32) return .{ .f = val };
    if (T == f64) return .{ .d = val };
    if (T == i8) return .{ .b = val };
    if (T == i16) return .{ .s = val };
    if (@typeInfo(T) == .pointer or T == cjni.jobject or T == cjni.jstring or T == cjni.jclass) {
        return .{ .l = @ptrCast(val) };
    }
    if (@typeInfo(T) == .null) return .{ .l = null };

    @compileError("Unsupported argument type for JNI call: " ++ @typeName(T));
}

fn getRetChar(comptime s: []const u8) u8 {
    const idx = std.mem.lastIndexOfScalar(u8, s, ')') orelse @compileError("Invalid signature: " ++ s);
    if (idx + 1 >= s.len) @compileError("Incomplete signature: " ++ s);
    return s[idx + 1];
}

fn JniRetType(comptime s: []const u8) type {
    const c = getRetChar(s);
    return switch (c) {
        'V' => void,
        'Z' => bool,
        'I' => cjni.jint,
        'J' => cjni.jlong,
        'F' => cjni.jfloat,
        'D' => cjni.jdouble,
        'B' => cjni.jbyte,
        'C' => cjni.jchar,
        'S' => cjni.jshort,
        'L', '[' => cjni.jobject,
        else => @compileError("Unknown return type char: " ++ &[_]u8{c}),
    };
}
