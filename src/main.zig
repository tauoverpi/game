const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

//// video buffer //////////////////////////////////////////////////////////////

const video = struct {
    var buffer: []u8 = &[]u8{};

    pub fn clear() void {
        for (buffer) |*c| c.* = 0xff444444;
    }

    pub fn bind() void {}

    pub fn blit() void {}
};

//// networking ////////////////////////////////////////////////////////////////

const network = struct {
    pub fn fetch(url: []const u8) void {}
};

//// memory ////////////////////////////////////////////////////////////////////

const memory = struct {
    pub fn release(rid: usize) void {}
};

//// events ////////////////////////////////////////////////////////////////////

const Event = union(enum) {
    tick,
    resize: struct { width: usize, height: usize },
    focus: enum { lost, gained },
    mouse: Mouse,
    key: Key,
    socket: Socket,
    audio: Audio,

    pub const Mouse = union(enum) {
        move: struct { x: usize, y: usize },
        up: struct { x: usize, y: usize, button: Button },
        down: struct { x: usize, y: usize, button: Button },
        wheel: struct { dx: f64, dy: f64, dz: f64 },

        pub const Button = enum { Primary, Auxiliary, Secondary, Back, Forward };
    };

    pub const Key = union(enum) {
        up: struct { key: u32, alt: bool, ctrl: bool, meta: bool, shift: bool },
        down: struct { key: u32, alt: bool, ctrl: bool, meta: bool, shift: bool },
    };

    pub const Socket = union(enum) {
        open: struct {},
        message: struct {},
        err: struct {},
        close: struct {},
    };

    pub const Audio = struct {};
};

//// game state/update /////////////////////////////////////////////////////////

var game: struct {
    // TODO: figure out a better way to handle memory
    persistent: *Allocator = std.heap.page_allocator,
    tmp: *Allocator = undefined,

    const Game = @This();

    // TODO: physics loop
    // variables: t, dt, current_time, accumulator, current_state, previous_state
    // 1. new_time = sampleTime()
    // 2. frame_time = newtime - current_time
    // 3. if frame_time > 0.25 then frame_time = 0.25
    // 4. current_time = new_time
    // 5. accumulator += frame_time
    // 6. while accumulator >= dt do
    //      previous_state = current_state
    //      integrate(current_state, t, dt)
    //      t += dt
    //      accumulator -= dt
    // 7. alpha = accumulator / dt
    // 8. state = current_state * alpha + previous_state * (1.0 - alpha)
    // 9. render(state)

    // initalize game
    pub fn init(state: *Game, t: f64, w: usize, h: usize) !void {
        video.buffer = try state.allocator.persistentAlloc(u32, w * h);
        video.clear();
    }

    // update step
    pub fn step(state: *Game, t: f64, event: Event) void {
        var arena = std.heap.ArenaAllocator.init(state.persistent);
        defer arena.deinit();
        state.tmp = &arena.allocator;

        //state.physics();
        //state.render();
    }
} = .{};

//// library ///////////////////////////////////////////////////////////////////

// TODO: deallocation list
const GameAllocator = struct {};

//// callbacks /////////////////////////////////////////////////////////////////

export fn resizeCallback(t: f64, w: usize, h: usize) void {
    game.step(t, .{ .resize = .{ .width = w, .height = h } });
}

export fn focusCallback(t: f64, focused: bool) void {
    if (focused) { // bug workaround
        game.step(t, .{ .focus = .lost });
    } else game.step(t, .{ .focus = .gained });
}

export fn mouseMoveCallback(t: f64, x: usize, y: usize) void {
    game.step(t, .{ .mouse = .{ .move = .{ .x = x, .y = y } } });
}

export fn mouseCallback(t: f64, x: usize, y: usize, b: u32, click: bool) void {
    const button = @intToEnum(Event.Mouse.Button, @truncate(u3, b));
    if (click) { // bug workaround
        game.step(t, .{ .mouse = .{ .down = .{ .x = x, .y = y, .button = button } } });
    } else game.step(t, .{ .mouse = .{ .up = .{ .x = x, .y = y, .button = button } } });
}

export fn mouseWheelCallback(t: f64, dx: f64, dy: f64, dz: f64) void {
    game.step(t, .{ .mouse = .{ .wheel = .{ .dx = dx, .dy = dy, .dz = dz } } });
}

export fn keyCallback(t: f64, key: u32, alt: bool, ctrl: bool, meta: bool, shift: bool, dir: bool) void {
    if (dir) { // bug workaround
        game.step(t, .{ .key = .{ .up = .{ .key = key, .alt = alt, .ctrl = ctrl, .meta = meta, .shift = shift } } });
    } else game.step(t, .{ .key = .{ .down = .{ .key = key, .alt = alt, .ctrl = ctrl, .meta = meta, .shift = shift } } });
}
