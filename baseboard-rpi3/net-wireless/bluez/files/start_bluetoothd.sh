#!/bin/sh
# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Checks for a device specific configuration and if present, starts
# bluetoothd with that config file; otherwise, starts bluetoothd with
# the legacy board-specific configuration (main.conf) if the config file
# is present.

bluetooth_dir="/etc/bluetooth"
conf_file="${bluetooth_dir}/main.conf"

# Make a copy of main.conf to /var to make it editable
var_conf_file="/var/lib/bluetooth/main.conf"
cp "${conf_file}" "${var_conf_file}"
# For security, limit the file permissions to only user "bluetooth".
chown bluetooth: "${var_conf_file}"
chmod 0600 "${var_conf_file}"
# Set the DeviceID based on Chrome OS version.
os_version="$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release)"
hex_os_version="$(printf '%04x' "${os_version}")"
sed -i -E "s/(bluetooth:00e0:c405:)0000/\1${hex_os_version}/" "${var_conf_file}"

config_file_param="--configfile=${var_conf_file}"

exec /sbin/minijail0 -u bluetooth -g bluetooth -G \
  -c 3500 -n -- \
  /usr/libexec/bluetooth/bluetoothd "${BLUETOOTH_DAEMON_OPTION}" --nodetach \
  "${config_file_param}" --experimental
