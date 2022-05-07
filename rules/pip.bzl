# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Dependencies that linter rules depend on."""

load("@rules_python//python:pip.bzl", "pip_install")
load("@python3//:defs.bzl", "interpreter")

_WHEEL_BUILD_FILE_CONTENTS = """\
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "all_wheels",
    srcs = glob(["**/*.whl"])
)
"""

def _pip_wheel_impl(rctx):
    # First, check if an existing pre-built Python wheels repo exists, and if
    # so, use it instead of building one.
    python_wheel_repo_path = rctx.os.environ.get(
        "BAZEL_PYTHON_WHEELS_REPO",
        None,
    )
    if python_wheel_repo_path:
        rctx.report_progress("Mounting existing Python wheels repo")
        rctx.symlink(python_wheel_repo_path, ".")
        return

    # If a pre-built Python wheels repo does not exist, we need to build it.
    rctx.report_progress("No Python wheels repo detected, building it instead")

    # First, we install the Python wheel package so we can build other wheels.
    args = [
        rctx.path(rctx.attr.python_interpreter),
        "-m",
        "pip",
        "install",
        "wheel",
    ]
    rctx.report_progress("Installing the Python wheel package")
    result = rctx.execute(
        args,
        timeout = rctx.attr.timeout,
        quiet = rctx.attr.quiet,
    )
    if result.return_code:
        fail("pip_wheel failed: {} ({})".format(result.stdout, result.stderr))

    # Next, we download/build all the Python wheels for each requirement.
    args = [
        rctx.path(rctx.attr.python_interpreter),
        "-m",
        "pip",
        "wheel",
        "-r",
        rctx.path(rctx.attr.requirements),
        "-w",
        "./",
    ]
    rctx.report_progress("Pre-building Python wheels")
    result = rctx.execute(
        args,
        timeout = rctx.attr.timeout,
        quiet = rctx.attr.quiet,
    )
    if result.return_code:
        fail("pip_wheel failed: {} ({})".format(result.stdout, result.stderr))

    # We need a BUILD file to load the downloaded Python packages.
    rctx.file(
        "BUILD.bazel",
        _WHEEL_BUILD_FILE_CONTENTS,
    )

pip_wheel = repository_rule(
    implementation = _pip_wheel_impl,
    attrs = {
        "python_interpreter": attr.label(
            default = interpreter,
            allow_single_file = True,
            doc = "Python interpreter to use.",
        ),
        "requirements": attr.label(
            default = "//:requirements.txt",
            allow_single_file = True,
            doc = "Python requirements file describing package dependencies.",
        ),
        "quiet": attr.bool(
            default = True,
            doc = "If True, suppress printing stdout/stderr to the terminal.",
        ),
        "timeout": attr.int(
            default = 300,
            doc = "Timeout (in seconds) on the rule's execution duration.",
        ),
    },
    environ = ["BAZEL_PYTHON_WHEELS_REPO"],
)

def lowrisc_misc_linters_pip_dependencies():
    """
    Declares workspaces linting rules depend on.
    Make sure to call this in your WORKSPACE file.

    Make sure to call lowrisc_misc_linters_dependencies() from
    deps.bzl first.
    """
    pip_wheel(
        name = "lowrisc_misc_linters_wheels",
    )
    pip_install(
        name = "lowrisc_misc_linters_pip",
        python_interpreter_target = interpreter,
        requirements = Label("//:requirements.txt"),
        find_links = "@lowrisc_misc_linters_wheels//:all_wheels",
        extra_pip_args = ["--no-index"],
    )
