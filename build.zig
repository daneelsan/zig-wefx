const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Adds the option -Drelease=[bool] to create a release build, which by
    // default we set to ReleaseSmall.
    b.setPreferredReleaseMode(.ReleaseSmall);
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // EXAMPLES
    const lib = b.addSharedLibrary("wefx", "examples/example1.zig", .unversioned);
    lib.setBuildMode(mode);
    lib.setTarget(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        //.abi = .musl,
    });
    lib.addPackagePath("WEFX", "./wefx/WEFX.zig");
    lib.setOutputDir("./docs/");
    lib.install();
}
