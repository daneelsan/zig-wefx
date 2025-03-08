const std = @import("std");

pub fn build(b: *std.Build) void {
    const wefx_module = b.addModule("WEFX", .{
        .root_source_file = .{ .cwd_relative = "wefx/WEFX.zig" },
    });

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const exe = b.addExecutable(.{
        .name = "wefx-example",
        .root_source_file = .{ .cwd_relative = "examples/example1.zig" },
        .target = target,
        .optimize = .ReleaseSmall,
    });
    exe.entry = .disabled;
    exe.rdynamic = true;
    exe.root_module.addImport("WEFX", wefx_module);
    b.installArtifact(exe);
}
