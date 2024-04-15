#!/bin/sh
#
# Copyright 2012 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is given one argument: the base of the source directory of
# the package, and it prints a string on stdout with the numerical version
# number for said repo.

# Handle quote properly - captures both VERSION=2.22 or VERSION='2.24'
exec sed -nEe "s/^\s*VERSION='?([.0-9]+)'?/\\1/p" \
	"$(find "$1" -path '*/bfd/configure')"
