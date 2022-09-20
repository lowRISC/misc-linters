#!/usr/bin/env bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

WORKSPACE="@@WORKSPACE@@"

if [[ ! -z "${WORKSPACE}" ]]; then
    REPO="$(dirname "$(realpath ${WORKSPACE})")"
    cd ${REPO} || exit 1
elif [[ ! -z "${BUILD_WORKSPACE_DIRECTORY+is_set}" ]]; then
    cd ${BUILD_WORKSPACE_DIRECTORY} || exit 1
else
    echo "Neither WORKSPACE nor BUILD_WORKSPACE_DIRECTORY were set."
    echo "If this is a test rule, add 'workspace = \"//:WORKSPACE\"' to your rule."
    exit 1
fi

"@@LICENCE_CHECKER@@" --config="@@CONFIG@@" "$@"
