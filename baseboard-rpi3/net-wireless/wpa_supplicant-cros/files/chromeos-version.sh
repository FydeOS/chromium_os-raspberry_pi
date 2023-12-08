#!/bin/sh

# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Print wpa_supplicant version from <supplicant_root_dir>/src/common/version.h
# The regexp [gsub("-", "_", $3); gsub("devel", "pre", $3)] is used to change
# the upstreanm version format from "2.10-devel" to "2.10_pre" to match the ebuild
# file name format:
# https://devmanual.gentoo.org/ebuild-writing/file-format/index.html
awk '$2 == "VERSION_STR" {gsub("\"", "", $3); gsub("-", "_", $3); gsub("devel", "pre", $3); print $3}' "$1"/src/common/version.h
