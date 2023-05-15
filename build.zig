const std = @import("std");

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const ptk = b.addModule("ptk", .{ .source_file = .{
        .path = "./vendor/parser-toolkit/src/main.zig",
    } });

    _ = b.addModule("mocha", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &.{.{ .module = ptk, .name = "ptk" }},
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });

    tests.addModule("ptk", ptk);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
