#!/bin/bash
# Copyright (c) 2026 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.
#
# Update the device tree, the device tree overlays and the Raspberry Pi boot
# firmware on the EFI partition during a post-install / OTA.
#
# Without this, an OTA writes a new kernel next to the device tree that was
# laid down when the image was first flashed, so a kernel that needs new
# bindings boots against a stale DT.
#
# Ownership rules, do not break them:
#   config.txt   is rewritten by config_kernel() in update_kernel_lib.sh
#   cmdline.txt  is rewritten by modify_root() in switch_root.sh
# Both run before this code, so anything here that touched them would undo the
# slot the installer just selected. They are refused explicitly below.
#
# The payload comes from /usr/share/raspberry-boot, installed by
# chromeos-base/raspberry-bootloader-update (USE=ota_update_boot_firmware).
# When that package is not installed there is nothing to copy and every
# function here degrades to a no-op, so the postinst still succeeds on boards
# that do not ship the payload.

BOOTLOADER_DIR="${BOOTLOADER_DIR:-/usr/share/raspberry-boot}"
DTB_OVERLAY_SUBDIR="overlays"

# Owned by the kernel/root-switch code. Never written from here.
DTB_PROTECTED="config.txt cmdline.txt"

dtb_log() {
  echo "$(date) $@" >> /tmp/update_kernel.log
}

dtb_md5() {
  local out
  out=$(md5sum "$1" 2>/dev/null) || return 1
  echo "${out%% *}"
}

dtb_is_protected() {
  local name p
  name=$(basename "$1")
  for p in ${DTB_PROTECTED}; do
    [ "${name}" = "${p}" ] && return 0
  done
  return 1
}

# dtb_needs_update <src> <dst>
dtb_needs_update() {
  [ ! -f "$2" ] || [ "$(dtb_md5 "$1")" != "$(dtb_md5 "$2")" ]
}

# Copy one file into place without ever leaving a truncated boot file behind:
# write a sibling temp then rename over the target.
# dtb_install_file <src> <dst>
dtb_install_file() {
  local src=$1 dst=$2 tmp="$2.new"
  if ! cp -f "${src}" "${tmp}"; then
    dtb_log "failed writing ${tmp}"
    rm -f "${tmp}"
    return 1
  fi
  if ! mv -f "${tmp}" "${dst}"; then
    dtb_log "failed renaming ${tmp} -> ${dst}"
    rm -f "${tmp}"
    return 1
  fi
  return 0
}

# dtb_copy_set <src_dir> <dst_dir> <glob> <description>
# Copies only what changed. Echoes the number of files written.
dtb_copy_set() {
  local src_dir=$1 dst_dir=$2 glob=$3 desc=$4
  local src dst count=0 failed=0

  [ -d "${src_dir}" ] || return 0
  mkdir -p "${dst_dir}" || { dtb_log "cannot create ${dst_dir}"; return 1; }

  for src in "${src_dir}"/${glob}; do
    [ -f "${src}" ] || continue
    if dtb_is_protected "${src}"; then
      dtb_log "refusing to overwrite installer-owned $(basename "${src}")"
      continue
    fi
    dst="${dst_dir}/$(basename "${src}")"
    dtb_needs_update "${src}" "${dst}" || continue
    if dtb_install_file "${src}" "${dst}"; then
      count=$((count + 1))
    else
      failed=$((failed + 1))
    fi
  done

  dtb_log "${desc}: ${count} updated, ${failed} failed"
  [ "${failed}" -eq 0 ]
}

# dtb_required_kb <src_dir> <dst_dir>
# Net additional KiB the copy needs. Files already on the target are replaced
# in place, so they only cost their growth; only genuinely new files cost their
# full size. Comparing the whole payload against free space instead would
# wrongly refuse to run: switch_root.sh writes the second kernel first, which
# on a real board leaves ~16 MiB free against a ~17 MiB payload that is
# almost entirely overwrite.
# Uses one find per directory rather than per-file stat, and no md5 - this is
# a size question, the copy pass does the content comparison.
dtb_required_kb() {
  local src_dir=$1 dst_dir=$2
  [ -d "${src_dir}" ] || { echo 0; return 0; }
  local -A have=()
  local size name total=0 delta
  if [ -d "${dst_dir}" ]; then
    while read -r size name; do
      have["${name}"]=${size}
    done < <(find "${dst_dir}" -maxdepth 1 -type f -printf '%s %f\n' 2>/dev/null)
  fi
  while read -r size name; do
    delta=$(( size - ${have[${name}]:-0} ))
    [ "${delta}" -gt 0 ] && total=$(( total + delta ))
  done < <(find "${src_dir}" -maxdepth 1 -type f -printf '%s %f\n' 2>/dev/null)
  echo $(( (total + 1023) / 1024 ))
}

# update_boot_payload <efi_mount_point>
# Refresh device tree, overlays and boot firmware on the mounted EFI partition.
update_boot_payload() {
  local efi=$1
  local need free

  if [ ! -d "${BOOTLOADER_DIR}" ]; then
    dtb_log "no ${BOOTLOADER_DIR}, skipping device tree update"
    return 0
  fi
  if [ -z "${efi}" ] || [ ! -d "${efi}" ]; then
    dtb_log "bad efi mount point '${efi}', skipping device tree update"
    return 1
  fi

  # The EFI partition is 64 MiB and by this point already carries two kernels,
  # so refuse to start rather than half-write the device tree into a full
  # filesystem. Only the net growth matters, see dtb_required_kb.
  need=$(( $(dtb_required_kb "${BOOTLOADER_DIR}" "${efi}") \
         + $(dtb_required_kb "${BOOTLOADER_DIR}/${DTB_OVERLAY_SUBDIR}" \
               "${efi}/${DTB_OVERLAY_SUBDIR}") ))
  free=$(df -Pk "${efi}" | awk 'NR==2 {print $4}')
  if [ -n "${free}" ] && [ -n "${need}" ] && \
     [ "${free}" -lt "$((need + 1024))" ]; then
    dtb_log "not enough room on ${efi}: payload ${need}KiB, free ${free}KiB, skipping"
    return 1
  fi
  dtb_log "refreshing device tree and firmware on ${efi}"

  local rc=0
  dtb_copy_set "${BOOTLOADER_DIR}" "${efi}" '*.dtb' "device tree" || rc=1
  dtb_copy_set "${BOOTLOADER_DIR}/${DTB_OVERLAY_SUBDIR}" \
    "${efi}/${DTB_OVERLAY_SUBDIR}" '*.dtbo' "device tree overlays" || rc=1
  dtb_copy_set "${BOOTLOADER_DIR}" "${efi}" '*.dat' "firmware (dat)" || rc=1
  dtb_copy_set "${BOOTLOADER_DIR}" "${efi}" '*.bin' "firmware (bin)" || rc=1
  dtb_copy_set "${BOOTLOADER_DIR}" "${efi}" '*.elf' "firmware (elf)" || rc=1

  sync
  return "${rc}"
}
