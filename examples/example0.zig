const std = @import("std");

const WEFX = @import("WEFX");

// The top-left is (0,0) and the pixel coordinates increase in the right and down directions.
// The pixel centers have integer coordinates.
const width = 105;
const height = 50;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var rng = std.rand.DefaultPrng.init(42);
const random = rng.random();

var wefx: WEFX = undefined;

export fn init() ?*WEFX {
    wefx = WEFX.init(arena.allocator());

    wefx.open(width, height) catch return null;

    wefx.clearColor(0x00, 0x00, 0x00);
    wefx.color(0xFF, 0xFF, 0xFF);
    wefx.clear();

    return &wefx;
}

fn draw() void {
    wefx.clear();
    wefx.color(0xEE, 0xDD, 0xCC);
    wefx.color(random.int(u8), random.int(u8), random.int(u8));

    // W
    wefx.line(15, 15, 20, 35);
    wefx.line(20, 35, 22, 25);
    wefx.line(23, 25, 25, 35);
    wefx.line(25, 35, 30, 15);
    // E
    wefx.line(50, 15, 35, 15);
    wefx.line(45, 25, 35, 25);
    wefx.line(50, 35, 35, 35);
    wefx.line(35, 15, 35, 35);
    // F
    wefx.line(70, 15, 55, 15);
    wefx.line(65, 25, 55, 25);
    wefx.line(55, 15, 55, 35);
    // X
    wefx.line(75, 15, 90, 35);
    wefx.line(90, 15, 75, 35);
}

export fn main_loop(time: f32) void {
    _ = time;
    draw();
}
