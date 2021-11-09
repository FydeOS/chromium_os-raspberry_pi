#!/usr/bin/awk -f

# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

BEGIN {
  found_device=0
}

{
  # A snippet of dbus-send output about an example paired device:
  #
  #   object path "/org/bluez/hci0/dev_7C_1E_52_6B_DD_E5"
  #   ...
  #       dict entry(
  #          string "Class"
  #             variant                         uint32 9600
  #       )

  # Change bluetooth address from something like 7C:1E:52:6B:DD:E5
  # to 7C_1E_52_6B_DD_E5 since the object path output by dbus-send
  # looks like "/org/bluez/hci0/dev_7C_1E_52_6B_DD_E5".
  if (addr ~ ":") {
    sub(/:/, "_", addr)
  }

  if ($1 == "object" && $2 == "path") {
    if ($3 ~ addr) {
      found_device = 1
    } else {
      found_device = 0
    }
  } else if (found_device == 1) {
    if ($1 == "string" && $2 ~ /"Class"/) {
      getline line
      n = split(line, array, " ")
      if (n == 3 && array[1] == "variant") {
        class = array[3]
        exit
      }
    }
  }
}

END {
  if (found_device == 1) {
    print class
  }
}
