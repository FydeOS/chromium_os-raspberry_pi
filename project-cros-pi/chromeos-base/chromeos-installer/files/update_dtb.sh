#!/bin/bash
# Copyright (c) 2026 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.
#
# Manually refresh the device tree, overlays and boot firmware on the EFI
# partition of the running system. The same work runs automatically from
# switch_root.sh during a post-install / OTA; this is the counterpart of
# update_kernel.sh for recovering a device whose DT is out of step.

. /usr/share/cros/update_kernel_lib.sh
. /usr/share/cros/update_dtb_lib.sh

main() {
  local root_dev=$(rootdev)
  local part_num=${root_dev##*[a-z]}
  local efi_dev=${root_dev/%$part_num/$EFI_NUM}
  update_boot_payload $(get_mp_by_device $efi_dev)
  local rc=$?
  release_mount
  return $rc
}

main $@
