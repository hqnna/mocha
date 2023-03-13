const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const library = b.addStaticLibrary(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
        .name = "mocha",
    });

    library.install();

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&library.step);
    test_step.dependOn(&tests.step);
}
