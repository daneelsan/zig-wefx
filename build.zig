const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const wefx_module = b.addModule("WEFX", .{
        .source_file = .{ .cwd_relative = "wefx/WEFX.zig" },
    });

    const lib = b.addSharedLibrary(.{
        .name = "wefx-example",
        .root_source_file = .{ .path = "examples/example1.zig" },
        .target = .{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        },
        .optimize = .ReleaseSmall,
    });
    lib.rdynamic = true;
    lib.addModule("WEFX", wefx_module);
    b.installArtifact(lib);
}
