# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Bazel rules for lowRISC linters."""

def _licence_check_impl(ctx):
    config = ctx.file.config
    if not config:
        config = ctx.actions.declare_file(ctx.label.name + ".hjson")
        ctx.actions.expand_template(
            template = ctx.file._config,
            output = config,
            substitutions = {
                "@@LICENCE@@": "'''" + ctx.attr.licence + "'''",
                "@@MATCH_REGEX@@": "true" if ctx.attr.match_regex else "false",
                "@@EXCLUDE_PATHS@@": ", ".join(['"{}"'.format(pat) for pat in ctx.attr.exclude_patterns]),
            },
        )

    # Hack to make Bazel build the checker correctly.
    #
    # Bazel py_binaries require a .runfiles directory to be present, but for
    # some reason or another it does not provide a good way to extract those
    # for building as a dependency from a PyInfo provider.
    #
    # https://github.com/bazelbuild/bazel/issues/7357
    checker = ctx.actions.declare_file(ctx.label.name + ".checker-witness")
    ctx.actions.run_shell(
        tools = [ctx.executable.licence_check],
        outputs = [checker],
        command = 'touch "{}"'.format(checker.path),
    )

    workspace = ctx.file.workspace.path if ctx.file.workspace else ""
    script = ctx.actions.declare_file(ctx.label.name + ".bash")
    ctx.actions.expand_template(
        template = ctx.file._runner,
        output = script,
        substitutions = {
            "@@LICENCE_CHECKER@@": ctx.executable.licence_check.path,
            "@@CONFIG@@": config.path,
            "@@WORKSPACE@@": workspace,
        },
        is_executable = True,
    )

    files = [config, checker]
    if ctx.file.workspace:
        files.append(ctx.file.workspace)

    runfiles = ctx.runfiles(files = files, transitive_files = ctx.attr.licence_check.files)
    runfiles = runfiles.merge(
        ctx.attr.licence_check.default_runfiles,
    )

    return DefaultInfo(
        runfiles = runfiles,
        executable = script,
    )

licence_check_attrs = {
    "config": attr.label(
        allow_single_file = True,
        doc = "HJSON configuration file override for the licence checker",
    ),
    "licence": attr.string(
        mandatory = True,
        doc = "Text of the licence header to use",
    ),
    "match_regex": attr.bool(
        default = False,
        doc = "Whether to use regex-matching for the licence text",
    ),
    "exclude_patterns": attr.string_list(
        default = [],
        doc = "File patterns to exclude from licence enforcement",
    ),
    "licence_check": attr.label(
        default = "//licence-checker",
        cfg = "host",
        executable = True,
        doc = "The licence checker executable",
    ),
    "workspace": attr.label(
        allow_single_file = True,
        doc = "Label of the WORKSPACE file",
    ),
    "_runner": attr.label(
        default = "//rules:licence-checker-runner.template.sh",
        allow_single_file = True,
    ),
    "_config": attr.label(
        default = "//rules:licence-checker-config.template.hjson",
        allow_single_file = True,
    ),
}

licence_check = rule(
    implementation = _licence_check_impl,
    attrs = licence_check_attrs,
    executable = True,
)

_licence_test = rule(
    implementation = _licence_check_impl,
    attrs = licence_check_attrs,
    test = True,
)

def _ensure_tag(tags, *tag):
    for t in tag:
        if t not in tags:
            tags.append(t)
    return tags

def licence_test(**kwargs):
    # Note: the "external" tag is a workaround for bazelbuild#15516.
    tags = kwargs.get("tags", [])
    kwargs["tags"] = _ensure_tag(tags, "no-sandbox", "no-cache", "external")
    _licence_test(**kwargs)
