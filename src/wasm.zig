const std = @import("std");
const App = @import("app");
const Engine = @import("Engine.zig");
const structs = @import("structs.zig");
const enums = @import("enums.zig");

const js = struct {
    extern fn machCanvasInit(width: u32, height: u32, selector_id: *u8) CanvasId;
    extern fn machCanvasDeinit(canvas: CanvasId) void;
    extern fn machCanvasSetTitle(canvas: CanvasId, title: [*]const u8, len: u32) void;
    extern fn machCanvasSetSize(canvas: CanvasId, width: u32, height: u32) void;
    extern fn machCanvasGetWidth(canvas: CanvasId) u32;
    extern fn machCanvasGetHeight(canvas: CanvasId) u32;

    extern fn machPerfNow() f64;
    extern fn machLog(str: [*]const u8, len: u32) void;
    extern fn machLogWrite(str: [*]const u8, len: u32) void;
    extern fn machLogFlush() void;
    extern fn machPanic(str: [*]const u8, len: u32) void;
};

pub const CanvasId = u32;

pub const Core = struct {
    id: CanvasId,
    selector_id: []const u8,

    pub fn init(allocator: std.mem.Allocator, eng: *Engine) !Core {
        const options = eng.options;
        var selector = [1]u8{0} ** 15;
        const id = js.machCanvasInit(options.width, options.height, &selector[0]);

        const title = std.mem.span(options.title);
        js.machCanvasSetTitle(id, title.ptr, title.len);

        return Core{
            .id = id,
            .selector_id = try allocator.dupe(u8, selector[0 .. selector.len - @as(u32, if (selector[selector.len - 1] == 0) 1 else 0)]),
        };
    }

    pub fn setShouldClose(_: *Core, _: bool) void {}

    pub fn getFramebufferSize(_: *Core) !structs.Size {
        return structs.Size{ .width = 0, .height = 0 };
    }

    pub fn getWindowSize(core: *Core) !structs.Size {
        return structs.Size{
            .width = js.machCanvasGetWidth(core.id),
            .height = js.machCanvasGetHeight(core.id),
        };
    }

    pub fn setSizeLimits(_: *Core, _: structs.SizeOptional, _: structs.SizeOptional) !void {}

    pub fn pollEvent(_: *Core) ?structs.Event {
        return null;
    }
};

pub const GpuDriver = struct {
    pub fn init(_: std.mem.Allocator, _: *Engine) !GpuDriver {
        return GpuDriver{};
    }
};

pub const BackingTimer = struct {
    initial: f64 = undefined,

    const WasmTimer = @This();

    pub fn start() !WasmTimer {
        return WasmTimer{ .initial = js.machPerfNow() };
    }

    pub fn read(timer: *WasmTimer) u64 {
        return timeToNs(js.machPerfNow() - timer.initial);
    }

    pub fn reset(timer: *WasmTimer) void {
        timer.initial = js.machPerfNow();
    }

    pub fn lap(timer: *WasmTimer) u64 {
        const now = js.machPerfNow();
        const initial = timer.initial;
        timer.initial = now;
        return timeToNs(now - initial);
    }

    fn timeToNs(t: f64) u64 {
        return @floatToInt(u64, t) * 1000000;
    }
};

var app: App = undefined;
var engine: Engine = undefined;

export fn wasmInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const options = if (@hasDecl(App, "options")) App.options else structs.Options{};
    engine = Engine.init(allocator, options) catch unreachable;

    app.init(&engine) catch {};
}

export fn wasmUpdate() bool {
    return app.update(&engine) catch false;
}

export fn wasmDeinit() void {
    app.deinit(&engine);
}

pub const log_level = .info;

const LogError = error{};
const LogWriter = std.io.Writer(void, LogError, writeLog);

fn writeLog(_: void, msg: []const u8) LogError!usize {
    js.machLogWrite(msg.ptr, msg.len);
    return msg.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const writer = LogWriter{ .context = {} };

    writer.print(message_level.asText() ++ prefix ++ format ++ "\n", args) catch return;
    js.machLogFlush();
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    js.machPanic(msg.ptr, msg.len);
    unreachable;
}