#!/bin/bash

# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Modified by (c) 2020 Fyde Innovations.

# Creates a hybrid MBR which points the MBR partition 1 to GPT
# partition 12 (ESP).
install_hybrid_mbr() {
  info "Creating hybrid MBR"
  locate_gpt
  local start_esp=$(partoffset "$1" 12)
  local num_esp_sectors=$(partsize "$1" 12)
  sudo sfdisk -Y dos "$1" <<EOF
unit: sectors

disk1 : start=   ${start_esp}, size=    ${num_esp_sectors}, Id= c, bootable
disk2 : start=   1, size=    1, Id= ee
EOF
}

get_target_uuid() {
  local partnum=$1
  local diskimage=$2
  cgpt show -i $partnum -u $diskimage
}

modify_root() {
  local diskimage=$1
  local target_cmdline=$2
  local uuid=$(get_target_uuid 3 $diskimage)
  sudo sed -i "s|/dev/mmcblk0p3|PARTUUID=${uuid}|" $target_cmdline
}

install_raspberrypi_bootloader() {
  local efi_offset_sectors=$(partoffset "$1" 12)
  local efi_size_sectors=$(partsize "$1" 12)
  local efi_offset=$(( efi_offset_sectors * 512 ))
  local efi_size=$(( efi_size_sectors * 512 ))
  local mount_opts=loop,offset=${efi_offset},sizelimit=${efi_size}
  local efi_dir=$(mktemp -d)
  local kernel_img=$(ls "${ROOT}/boot/zImage-"*)
  local target_img="${efi_dir}/kernel7l.img"
  if [ -z "$kernel_img" ]; then
    kernel_img=$(ls "${ROOT}/boot/Image"*)
    target_img="${efi_dir}/kernel8_a.img"
  fi
  sudo mount -o "${mount_opts}"  "$1" "${efi_dir}"

  info "Installing firmware, kernel and overlays"
  sudo cp -r "${ROOT}/firmware/rpi/"* "${efi_dir}/"
  modify_root $1 ${efi_dir}/cmdline.txt
  if [ -d ${ROOT}/usr/src/linux/arch/arm/boot/dts ]; then
    sudo cp ${ROOT}/usr/src/linux/arch/arm/boot/dts/*.dtb "${efi_dir}/"
    sudo cp -r ${ROOT}/usr/src/linux/arch/arm/boot/dts/overlays "${efi_dir}/"
  else
    sudo cp ${ROOT}/usr/src/linux/arch/arm64/boot/dts/broadcom/*.dtb "${efi_dir}/"
    sudo cp -r ${ROOT}/usr/src/linux/arch/arm64/boot/dts/overlays "${efi_dir}/"
  fi
  sudo cp ${kernel_img} ${target_img}
  sudo umount "${efi_dir}"
  rmdir "${efi_dir}"
}

board_setup() {
  install_raspberrypi_bootloader "$1" 
  install_hybrid_mbr "$1"
}

skip_blacklist_check=1
skip_test_image_content=1
