# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Dependencies for linter rules."""

load("@rules_python//python:repositories.bzl", "python_register_toolchains")

def lowrisc_misc_linters_dependencies():
    if not native.existing_rule("python3"):
        python_register_toolchains(
            name = "python3",
            python_version = "3.9",
        )
