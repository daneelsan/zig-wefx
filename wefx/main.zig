pub const WEFX = @import("WEFX.zig");

export fn wefx_width(wefx: *WEFX) u32 {
    return wefx.width;
}

export fn wefx_height(wefx: *WEFX) u32 {
    return wefx.height;
}

export fn wefx_screen_offset(wefx: *WEFX) [*]u32 {
    return wefx.screen.ptr;
}

export fn wefx_flush(wefx: *WEFX) void {
    wefx.flush();
}
