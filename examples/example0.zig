const std = @import("std");

const wefx = @import("wefx");

// The top-left is (0,0) and the pixel coordinates increase in the right and down directions.
// The pixel centers have integer coordinates.
const width = 105;
const height = 50;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var rng = std.rand.DefaultPrng.init(42);
const random = rng.random();

var w: wefx.WEFX = undefined;

export fn init() ?*wefx.WEFX {
    w = wefx.WEFX.init(arena.allocator());

    w.open(width, height) catch return null;

    w.clearColor(0x00, 0x00, 0x00);
    w.color(0xFF, 0xFF, 0xFF);
    w.clear();

    return &w;
}

fn draw() void {
    w.clear();
    w.color(0xEE, 0xDD, 0xCC);
    w.color(random.int(u8), random.int(u8), random.int(u8));

    // W
    w.line(15, 15, 20, 35);
    w.line(20, 35, 22, 25);
    w.line(23, 25, 25, 35);
    w.line(25, 35, 30, 15);
    // E
    w.line(50, 15, 35, 15);
    w.line(45, 25, 35, 25);
    w.line(50, 35, 35, 35);
    w.line(35, 15, 35, 35);
    // F
    w.line(70, 15, 55, 15);
    w.line(65, 25, 55, 25);
    w.line(55, 15, 55, 35);
    // X
    w.line(75, 15, 90, 35);
    w.line(90, 15, 75, 35);
}

export fn main_loop(time: f32) void {
    _ = time;
    draw();
}
