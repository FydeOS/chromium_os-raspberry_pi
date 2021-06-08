#!/bin/sh
#
# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This echo statement sets the package base version (without its -r value).
# If it is necessary to add a new blocker or version dependency on this ebuild
# at the same time as revving the ebuild to a known version value, editing this
# version can be useful.
echo 0.0.2
