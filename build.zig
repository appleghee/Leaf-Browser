const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "leaf-browser",
        .root_module = exe_mod,
    });

    if (target.result.os.tag == .windows) {
        exe_mod.linkSystemLibrary("user32", .{});
        exe_mod.linkSystemLibrary("ole32", .{});
        exe_mod.linkSystemLibrary("shlwapi", .{});
        exe_mod.linkSystemLibrary("advapi32", .{});

        if (optimize != .Debug) {
            exe.subsystem = .Windows;
        }
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run Leaf Browser");
    run_step.dependOn(&run_cmd.step);

    const url_tests_mod = b.createModule(.{
        .root_source_file = b.path("src/browser/url.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{
        .name = "leaf-browser-url-tests",
        .root_module = url_tests_mod,
    });

    const test_cmd = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_cmd.step);
}
