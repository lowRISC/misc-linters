# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Repositories to provide dependencies for the linter rules."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def lowrisc_misc_linters_repos():
    """Declares workspaces linting rules depend on.
    Make sure to call this in your WORKSPACE file."""
    if not native.existing_rule("rules_python"):
        http_archive(
            name = "rules_python",
            sha256 = "9fcf91dbcc31fde6d1edb15f117246d912c33c36f44cf681976bd886538deba6",
            strip_prefix = "rules_python-0.8.0",
            url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.8.0.tar.gz",
        )
