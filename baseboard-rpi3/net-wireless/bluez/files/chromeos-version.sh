#!/bin/sh
# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

sed -n '/AC_INIT(bluez/{s/.*, *//;s/).*//;p}' < "$1/configure.ac"
