#!/bin/bash
# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script queries dbus about the bluetooth HID device type.

DBUS_MSG="org.freedesktop.DBus.ObjectManager.GetManagedObjects"
DBUS_SEND_CMD="dbus-send --system --print-reply --dest=org.bluez / ${DBUS_MSG}"
PROG_GET_CLASS="dbus_send_blutooth_class.awk"

# Refer to the follow URL for bluetooth class of device and service fields.
# https://www.bluetooth.com/specifications/assigned-numbers/baseband
# Note that a mask is 24 bits long.
PERIPHERAL_MAJOR_MASK="0x000500"
PERIPHERAL_MINOR_MASK="0x0000C0"
KEYBOARD_DEVICE="0x000040"
POINTING_DEVICE="0x000080"
COMBO_DEVICE="0x0000C0"

# Remove the prefix and suffix quotes of the bluetooth device address,
# and convert it to upper case.
BD_ADDR="$1"
BD_ADDR="${BD_ADDR#\"}"
BD_ADDR="${BD_ADDR%\"}"
BD_ADDR="${BD_ADDR^^}"

BD_CLASS="$(${DBUS_SEND_CMD} | ${PROG_GET_CLASS} addr=${BD_ADDR})"
if [[ -n "${BD_CLASS}" &&
      $((BD_CLASS & PERIPHERAL_MAJOR_MASK)) -ne 0 ]]; then
  MINOR_DEVICE=$((BD_CLASS & PERIPHERAL_MINOR_MASK))
  case "${MINOR_DEVICE}" in
    $((KEYBOARD_DEVICE))) echo keyboard ;;
    $((POINTING_DEVICE))) echo mouse ;;
    $((COMBO_DEVICE))) echo combo ;;
  esac
fi
