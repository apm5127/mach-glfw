const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const glfw_dep = b.dependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    });

    var module = b.addModule("mach-glfw", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });
    module.linkLibrary(glfw_dep.artifact("glfw"));

    const test_step = b.step("test", "Run library tests");
    const main_tests = b.addTest(.{ .name = "glfw-tests", .root_module = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    }) });

    main_tests.root_module.linkLibrary(glfw_dep.artifact("glfw"));

    b.installArtifact(main_tests);
    test_step.dependOn(&b.addRunArtifact(main_tests).step);

    if (target.result.os.tag.isDarwin()) {
        if (glfw_dep.builder.lazyDependency("xcode_frameworks", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addSystemFrameworkPath(dep.path("Frameworks"));
            module.addSystemIncludePath(dep.path("include"));
            module.addLibraryPath(dep.path("lib"));

            main_tests.root_module.addSystemFrameworkPath(dep.path("Frameworks"));
            main_tests.root_module.addSystemIncludePath(dep.path("include"));
            main_tests.root_module.addLibraryPath(dep.path("lib"));
        }
    }
}
