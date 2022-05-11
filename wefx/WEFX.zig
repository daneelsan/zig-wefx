const std = @import("std");

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

allocator: Allocator = undefined,

width: u32 = 0,
height: u32 = 0,

foreground_color: u32 = 0x00_00_00_00,
background_color: u32 = 0x00_00_00_00,

event_queue: EventQueue = undefined,

screen: []u32 = undefined,
buffer: []u32 = undefined,

const Self = @This();

const EventQueue = std.TailQueue(Event);

pub const EventType = enum {
    keydown,
    keypress,
    keyup,
    mousemove,
    mousedown,
    mouseup,

    pub inline fn isKeyboardEvent(event_type: EventType) bool {
        return event_type == .keydown or event_type == .keypress or event_type == .keyup;
    }

    pub inline fn isMouseEvent(event_type: EventType) bool {
        return event_type == .mousemove or event_type == .mousedown or event_type == .mouseup;
    }
};

pub const MouseEvent = struct {
    // alt_key: bool,
    button: Button,
    // meta_key: bool,
    x: u32,
    y: u32,

    pub const Button = enum {
        main,
        auxiliary,
        secondary,
        fourth,
        fifth,
    };
};

pub const KeyboardEvent = struct {
    // alt_key: bool,
    // ctrl_key: bool,
    // meta_key: bool,
    // repeat: bool,
    // shift_key: bool,
    key: u8,
};

pub const Event = struct {
    timestamp: f32,
    event_type: EventType,
    event: union {
        keyboard: KeyboardEvent,
        mouse: MouseEvent,
    },

    pub fn initKeyboardEvent(timestamp: f32, event_type: EventType, kbd_event: KeyboardEvent) Event {
        assert(event_type.isKeyboardEvent());

        return Event{
            .timestamp = timestamp,
            .event_type = event_type,
            .event = .{
                .keyboard = kbd_event,
            },
        };
    }

    pub fn initMouseEvent(timestamp: f32, event_type: EventType, mouse_event: MouseEvent) Event {
        assert(event_type.isMouseEvent());

        return Event{
            .timestamp = timestamp,
            .event_type = event_type,
            .event = .{
                .mouse = mouse_event,
            },
        };
    }

    pub fn keyboardEvent(self: Event) KeyboardEvent {
        assert(self.event_type.isKeyboardEvent());
        return self.event.keyboard;
    }

    pub fn mouseEvent(self: Event) MouseEvent {
        assert(self.event_type.isMouseEvent()());
        return self.event.mouse;
    }
};

pub fn init(allocator: Allocator) Self {
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    var it = self.event_queue.first;
    while (it) |node| {
        it = node.next;
        self.allocator.destroy(node);
    }
    self.event_queue = undefined;

    self.allocator = undefined;
}

/// wefx.open(width, height) allocates memory for both the screen and buffer slices.
pub fn open(self: *Self, width: u32, height: u32) !void {
    self.width = width;
    self.height = height;

    self.buffer = try self.allocator.alloc(u32, width * height);
    self.screen = try self.allocator.alloc(u32, width * height);
}

pub fn close(self: *Self) void {
    self.allocator.free(self.buffer);
    self.buffer = undefined;

    self.allocator.free(self.screen);
    self.screen = undefined;

    self.width = 0;
    self.height = 0;
}

/// wefx.clearColor(r, g, b) sets the background color to RGB(r, g, b).
/// A subsequent call to wefx.clear() will "clear" the screen by setting every pixel to said color.
pub fn clearColor(self: *Self, r: u8, g: u8, b: u8) void {
    self.background_color = fromRGB(r, g, b);
}

/// wefx.clear() sets every pixel to the background color.
pub fn clear(self: *Self) void {
    const bg_color = self.background_color;
    for (self.buffer) |*v| {
        v.* = bg_color;
    }
}

/// wefx.color(r, g, b) sets the foreground color to RGB(r, g, b).
pub fn color(self: *Self, r: u8, g: u8, b: u8) void {
    self.foreground_color = fromRGB(r, g, b);
}

/// wefx.point(x, y) sets the value of the pixel located at (x, y) to the foreground color.
pub fn point(self: *Self, x: u32, y: u32) void {
    assert(x <= self.width and y <= self.height);

    self.buffer[x + y * self.width] = self.foreground_color;
}

/// wefx.line(x0, y0, x1, y1) draws a line from point (x0, y0) to point (x1, y1).
/// Uses Bresenham's line algorithm.
pub fn line(self: *Self, x0: u32, y0: u32, x1: u32, y1: u32) void {
    assert(x0 <= self.width and y0 <= self.height);
    assert(x1 <= self.width and y1 <= self.height);

    const dx = std.math.absInt(@as(i64, x1) - @as(i64, x0)) catch unreachable;
    //const sx: i64 = if (x0 < x1) 1 else -1;

    const dy = -1 * (std.math.absInt(@as(i64, y1) - @as(i64, y0)) catch unreachable);
    //const sy: i64 = if (y0 < y1) 1 else -1;

    var err = dx + dy;
    var x = x0;
    var y = y0;
    while (true) {
        self.point(x, y);
        if (x == x1 and y == y1) {
            break;
        }
        const err2 = 2 * err;
        if (err2 >= dy) {
            if (x == x1) {
                break;
            }
            err += dy;
            if (x0 < x1) {
                x += 1;
            } else {
                x -= 1;
            }
        }
        if (err2 <= dx) {
            if (y == y1) {
                break;
            }
            err += dx;
            if (y0 < y1) {
                y += 1;
            } else {
                y -= 1;
            }
        }
    }
}

/// wefx.cicle(x0, y0, r0) draws a circle with center (x0, y0) and radius r0.
/// Uses the midpoint circle algorithm.
pub fn circle(self: *Self, x0: u32, y0: u32, r0: u32) void {
    var x: u32 = r0;
    var y: u32 = 0;
    var err: i64 = 0;
    while (x >= y) {
        self.point(x0 + x, y0 + y);
        self.point(x0 + y, y0 + x);
        self.point(x0 - y, y0 + x);
        self.point(x0 - x, y0 + y);
        self.point(x0 - x, y0 - y);
        self.point(x0 - y, y0 - x);
        self.point(x0 + y, y0 - x);
        self.point(x0 + x, y0 - y);

        y += 1;
        err += 2 * @as(i64, y) + 1;
        if (err > 0) {
            x -= 1;
            err -= 2 * @as(i64, x) + 1;
        }
    }
}

pub fn flush(self: *Self) void {
    for (self.buffer) |val, i| {
        self.screen[i] = val;
    }
}

fn eventPushBack(self: *Self, event: Event) !void {
    var node_ptr = try self.allocator.create(EventQueue.Node);
    node_ptr.data = event;

    // TODO: set a maximum length for queue?
    self.event_queue.append(node_ptr);
}

pub fn eventPopFront(self: *Self) ?Event {
    const node_ptr = self.event_queue.popFirst() orelse return null;
    const event = node_ptr.data;
    self.allocator.destroy(node_ptr);
    return event;
}

// Utilities

inline fn fromRGB(r: u8, g: u8, b: u8) u32 {
    return fromRGBA(r, g, b, 0xFF);
}

inline fn fromRGBA(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, a) << 24) + (@as(u32, r) << 16) + (@as(u32, g) << 8) + (@as(u32, b) << 0);
}

// Exported functions

export fn wefx_xsize(self: *Self) u32 {
    return self.width;
}

export fn wefx_ysize(self: *Self) u32 {
    return self.height;
}

export fn wefx_screen_offset(self: *Self) [*]u32 {
    return self.screen.ptr;
}

export fn wefx_flush(self: *Self) void {
    self.flush();
}

export fn wefx_add_keyboard_event(
    self: *Self,
    event_type_val: u8,
    timestamp: f32,
    key: u8,
) void {
    const event_type = @intToEnum(EventType, event_type_val);
    const kbd_event = .{
        .key = key,
    };
    const event = Event.initKeyboardEvent(timestamp, event_type, kbd_event);
    // TODO: handle error on JS?
    self.eventPushBack(event) catch unreachable;
}

export fn wefx_add_mouse_event(
    self: *Self,
    event_type_val: u8,
    timestamp: f32,
    button_val: u8,
    x: f32,
    y: f32,
) void {
    const event_type = @intToEnum(EventType, event_type_val);
    const button = @intToEnum(MouseEvent.Button, button_val);

    const mouse_event = .{
        .button = button,
        .x = @floatToInt(u32, x),
        .y = @floatToInt(u32, y),
    };
    const event = Event.initMouseEvent(timestamp, event_type, mouse_event);
    // TODO: handle error on JS?
    self.eventPushBack(event) catch unreachable;
}

// comptime {
//     inline for (@typeInfo(EventType).Enum.fields) |field| {
//         const enum_val = @intToEnum(EventType, field.value);
//         const enum_name = @tagName(enum_val);
//         var field_value = struct {
//             pub const field_value: i32 = field.value;
//         }.field_value;
//         const opts = .{ .name = "wefx_" ++ enum_name, .linkage = .Strong };
//         @export(field_value, opts);
//     }
// }
export var wefx_keydown = @enumToInt(EventType.keydown);
export var wefx_keypress = @enumToInt(EventType.keypress);
export var wefx_keyup = @enumToInt(EventType.keyup);
export var wefx_mousemove = @enumToInt(EventType.mousemove);
export var wefx_mousedown = @enumToInt(EventType.mousedown);
export var wefx_mouseup = @enumToInt(EventType.mouseup);
