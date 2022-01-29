#!/bin/bash
#
# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is given one argument: the base of the source directory of
# the package, and it prints a string on stdout with the numerical version
# number for said repo.

# If the script runs from a board overlay, add "_p1" to returned kernel version.
SCRIPT=$(realpath "$0")
OVERLAY_ROOT="$(dirname "${SCRIPT}")/../../.."
OVERLAY_NAME=$(sed -n '/^repo-name *=/s:[^=]*= *::p' "${OVERLAY_ROOT}"/metadata/layout.conf)

# Only after we've parsed $0 change directory in case $0 is relative.
cd "$1" || exit

suffix=""
if [[ "${OVERLAY_NAME}" != "chromiumos" ]]; then
    suffix="_p1"
fi

# Strip any .0 fix level from the version string.
version=$(make kernelversion | sed -Ee 's/([0-9]*\.[0-9]*)\.0/\1/' -e s/-/_/g)

if [[ -n "${version}" ]]; then
    echo "${version}${suffix}"
fi
