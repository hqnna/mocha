const std = @import("std");

pub fn build(b: *std.Build) anyerror!void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const ptk = b.dependency("ptk", .{});

    _ = b.addModule("mocha", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &.{std.Build.ModuleDependency{
            .module = ptk.module("parser-toolkit"),
            .name = "ptk",
        }},
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });

    const test_step = b.step("test", "Run library tests");
    tests.addModule("ptk", ptk.module("parser-toolkit"));
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
