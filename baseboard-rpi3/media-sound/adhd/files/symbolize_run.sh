#!/bin/bash
# Copyright 2023 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
set -o pipefail
# shellcheck disable=SC2154  # Passed by ebuild.
"$@" |& asan_symbolize.py -d -s "${SYSROOT}"
