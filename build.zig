const std = @import("std");

const source = std.Build.FileSource{
    .path = "src/main.zig",
};

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const ptk = b.dependency("ptk", .{});

    const mocha = b.addModule("mocha", .{ .source_file = source });
    try mocha.dependencies.put("ptk", ptk.module("parser-toolkit"));

    const tests = b.addTest(.{
        .root_source_file = source,
        .optimize = optimize,
        .target = target,
    });

    const test_step = b.step("test", "Run library tests");
    tests.addModule("ptk", ptk.module("parser-toolkit"));
    test_step.dependOn(&tests.step);
}
