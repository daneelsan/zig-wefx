const std = @import("std");
const math = std.math;

const WEFX = @import("WEFX");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var rng = std.rand.DefaultPrng.init(42);
const random = rng.random();

var wefx: WEFX = undefined;

export fn init() ?*WEFX {
    wefx = WEFX.init(arena.allocator());

    wefx.open(1024, 768) catch return null;

    wefx.clearColor(0x00, 0x00, 0x00);
    wefx.clear();

    return &wefx;
}

fn draw(time: f32) void {
    wefx.clear();

    const width = wefx.width;
    const height = wefx.height;

    // int x = time % W;
    // wefx_point(x, (H / 2) + cos(time) * 2);

    const x = @floatToInt(u32, time) % width;
    wefx.point(x, (height / 2) + @floatToInt(u32, math.cos(time) * 2));

    var i: u32 = 0;
    while (i < 130) : (i += 1) {
        wefx.color(0xFF, 0, 0);
        wefx.point(x - i, (height / 2) + @floatToInt(u32, math.sin(time - @intToFloat(f32, i)) * 3) - 20);

        wefx.color(0, 0xFF, 0);
        wefx.point(x - i, (height / 2) + @floatToInt(u32, math.cos(time - @intToFloat(f32, i)) * 2));

        wefx.color(0, 0, 0xFF);
        wefx.point(x - i, (height / 2) + @floatToInt(u32, math.sin(time - @intToFloat(f32, i)) * 3) + 20);
    }

    wefx.color(0xFF, 0xFF, 0xFF);
    wefx.line(0, 0, width, height);
    wefx.line(0, height, width, 0);

    wefx.color(random.int(u8), random.int(u8), random.int(u8));
    wefx.line(width / 2, height / 2, random.uintLessThanBiased(u32, width), random.uintLessThanBiased(u32, height));

    wefx.circle(width >> 1, height >> 1, (height >> 1) - 5);
}

export fn main_loop(time: f32) void {
    draw(time);
}
