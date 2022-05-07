# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("//rules:rules.bzl", "licence_check", "yapf_check")

licence_check(
    name = "licence-check",
    exclude_patterns = [".style.yapf"],
    licence = """
    Copyright lowRISC contributors.
    Licensed under the Apache License, Version 2.0, see LICENSE for details.
    SPDX-License-Identifier: Apache-2.0
    """,
)

yapf_check(
    name = "yapf",
    mode = "diff",
)
