const std = @import("std");

const wefx = @import("wefx");

// The top-left is (0,0) and the pixel coordinates increase in the right and down directions.
// The pixel centers have integer coordinates.
const width = 105;
const height = 50;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

var rng = std.rand.DefaultPrng.init(42);
const random = rng.random();

export fn init() u32 {
    wefx.instance = wefx.WEFX.init(arena.allocator());
    wefx.instance.open(width, height) catch {
        // A non-zero return value is an error, which should be handled in JS.
        return 1;
    };

    // wefx_event_queue *queue = wefx_open_events();
    // if (queue == NULL)
    //     return 1;
    // enable mouse and keyboard events
    //wefx.instance.openEvents();

    wefx.instance.clearColor(0x00, 0x00, 0x00);
    wefx.instance.color(0xFF, 0xFF, 0xFF);
    wefx.instance.clear();

    return 0;
}

fn draw() void {
    wefx.instance.clear();
    wefx.instance.color(0xEE, 0xDD, 0xCC);
    wefx.instance.color(random.int(u8), random.int(u8), random.int(u8));

    // W
    wefx.instance.line(15, 15, 20, 35);
    wefx.instance.line(20, 35, 22, 25);
    wefx.instance.line(23, 25, 25, 35);
    wefx.instance.line(25, 35, 30, 15);
    // E
    wefx.instance.line(50, 15, 35, 15);
    wefx.instance.line(45, 25, 35, 25);
    wefx.instance.line(50, 35, 35, 35);
    wefx.instance.line(35, 15, 35, 35);
    // F
    wefx.instance.line(70, 15, 55, 15);
    wefx.instance.line(65, 25, 55, 25);
    wefx.instance.line(55, 15, 55, 35);
    // X
    wefx.instance.line(75, 15, 90, 35);
    wefx.instance.line(90, 15, 75, 35);
}

export fn main_loop(time: f32) void {
    _ = time;
    draw();
}
