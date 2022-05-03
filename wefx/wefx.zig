const std = @import("std");

const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub const WEFX = struct {
    allocator: Allocator = undefined,

    width: u32 = 0,
    height: u32 = 0,

    foreground_color: u32 = 0x00_00_00_00,
    background_color: u32 = 0x00_00_00_00,

    //event_queue: std.TailQueue(u32),

    screen: []u32 = undefined,
    buffer: []u32 = undefined,

    pub const EventType = enum {
        key_down,
        key_press,
        key_up,
        mouse_move,
        mouse_down,
        mouse_up,
        click,
    };

    pub const ButtonType = enum {
        none,
        left,
        right,
    };

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

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
                //x += sx;
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

    // pub fn addQueueEvent(event_type: u32) void {}

    // EXPORT void wefx_add_queue_event(int type, int button, int timestamp, int key, int x, int y)
    // {
    //     // if we don't care about events drop everything
    //     if (wefx_q == NULL)
    //         return;

    //     wefx_event *e = malloc(sizeof(struct wefx_event));
    //     if (e == NULL)
    //     {
    //         // we couldn't create memory for some reason
    //         // this seems to happen a bit when running in
    //         // wasm (or maybe walloc)
    //         return;
    //     }
    //     e->type = type;
    //     e->button = button;
    //     e->timestamp = timestamp;
    //     e->key = (char)key;
    //     e->x = x;
    //     e->y = y;

    //     wefx_enqueue(wefx_q, e);
    // }

    pub fn draw(self: *Self) void {
        for (self.buffer) |val, i| {
            self.screen[i] = val;
        }
    }
};

// Export

// var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// pub var instance = WEFX.init(arena.allocator());
pub var instance: WEFX = undefined;

export fn wefx_width() u32 {
    return instance.width;
}

export fn wefx_height() u32 {
    return instance.height;
}

export fn wefx_screen_offset() [*]u32 {
    return instance.screen.ptr;
}

export fn wefx_draw() void {
    instance.draw();
}

// Utilities

inline fn fromRGB(r: u8, g: u8, b: u8) u32 {
    return fromRGBA(r, g, b, 0xFF);
}

inline fn fromRGBA(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, a) << 24) + (@as(u32, r) << 16) + (@as(u32, g) << 8) + (@as(u32, b) << 0);
}
