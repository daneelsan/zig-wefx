pub inline fn fromRGB(r: u8, g: u8, b: u8) u32 {
    return fromRGBA(r, g, b, 0xFF);
}

pub inline fn fromRGBA(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, a) << 24) + (@as(u32, r) << 16) + (@as(u32, g) << 8) + (@as(u32, b) << 0);
}
