const std = @import("std");
const math = std.math;

const WEFX = @import("WEFX");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var rng = std.Random.DefaultPrng.init(42);
const random = rng.random();

var wefx: WEFX = undefined;

export fn init() ?*WEFX {
    wefx = WEFX.init(arena.allocator());

    wefx.open(1024, 768) catch return null;

    wefx.clearColor(0x00, 0x00, 0x00);
    wefx.clear();

    return &wefx;
}

fn input(time: f32) void {
    _ = time;

    while (true) {
        var event = wefx.eventPopFront() orelse return;
        switch (event.event_type) {
            .mousedown => {
                wefx.clearColor(random.int(u8), random.int(u8), random.int(u8));
            },
            .keydown => {
                const kbd_event = event.keyboardEvent();
                if (kbd_event.key == 'a') {
                    wefx.clearColor(random.int(u8), random.int(u8), random.int(u8));
                }
            },
            else => {},
        }
    }
}

fn draw(time: f32) void {
    wefx.clear();

    const width = wefx.width;
    const height = wefx.height;

    const x = @as(u32, @intFromFloat(time)) % width;
    wefx.point(x, (height / 2) + @as(u32, @intFromFloat(math.cos(time) * 2)));

    var i: u32 = 0;
    while (i < 130) : (i += 1) {
        wefx.color(0xFF, 0, 0);
        wefx.point(x - i, (height / 2) + @as(u32, @intFromFloat(math.sin(time - @as(f32, @floatFromInt(i))) * 3)) - 20);

        wefx.color(0, 0xFF, 0);
        wefx.point(x - i, (height / 2) + @as(u32, @intFromFloat(math.cos(time - @as(f32, @floatFromInt(i))) * 2)));

        wefx.color(0, 0, 0xFF);
        wefx.point(x - i, (height / 2) + @as(u32, @intFromFloat(math.sin(time - @as(f32, @floatFromInt(i))) * 3)) + 20);
    }

    wefx.color(0xFF, 0xFF, 0xFF);
    wefx.line(0, 0, width, height);
    wefx.line(0, height, width, 0);

    wefx.color(random.int(u8), random.int(u8), random.int(u8));
    wefx.line(width / 2, height / 2, random.uintLessThanBiased(u32, width), random.uintLessThanBiased(u32, height));

    wefx.circle(width >> 1, height >> 1, (height >> 1) - 5);
}

export fn main_loop(time: f32) void {
    input(time);
    draw(time);
}

// export fn deinit() void {
//     wefx.close();
//     wefx.deinit();
// }
