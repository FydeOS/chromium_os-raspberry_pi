#!/bin/bash
KERNAL_A="kernel8_a.img"
KERNAL_B="kernel8_b.img"
CONFIG="config.txt"
EFI_NUM=12
MOUNT_TRACK=""

log() {
  echo $(date) $@ >> /tmp/update_kernel.log
}

md5() {
  md5sum $1 | awk '{print $1}'
}

need_update() {
  local src_knl=$1
  local tgt_knl=$2
  [ ! -f "$tgt_knl" ] || [ "$(md5 $src_knl)" != "$(md5 $tgt_knl)" ]
}

get_target_kernel() {
  local root_part_num=$1
  if [ $root_part_num -eq 3 ]; then
    echo $KERNAL_A
  else
    echo $KERNAL_B
  fi
}

config_kernel() {
  local root_part_num=$1
  local configfile=$2
  local kernel=$(get_target_kernel $root_part_num)
  log "modify boot kernel to :${kernel}"
  sed -i "s/kernel=.*$/kernel=${kernel}/g" $configfile 
}

find_kernel() {
  local root=$1
  ls $root/boot/Image-* | head -n1
}

switch_kernel() {
  local efi_mount_point=$1
  local root_mount_point=$2
  local part_num=$3
  local src_knl=$(find_kernel $root_mount_point)
  local tgt_knl=${efi_mount_point}/$(get_target_kernel $part_num)
  if need_update $src_knl $tgt_knl; then
    log "replace old kernel by $src_knl"
    cp $src_knl $tgt_knl
    sync $tgt_knl
  fi
  config_kernel $part_num ${efi_mount_point}/${CONFIG}
  sync ${efi_mount_point}/${CONFIG}
}

get_mp_by_device() {
  local dev=$1
  local mp=$(lsblk -o mountpoint -n $dev)
  if [ -z "$mp" ]; then
    mp=$(mktemp -d)
    mount $dev $mp
    MOUNT_TRACK="$MOUNT_TRACK $mp"
  fi
  echo $mp
}

release_mount() {
  for mp in $MOUNT_TRACK;do
    umount $mp
  done
}

update_root_kernel() {
  local root_dev=$1
  local part_num=${root_dev##*[a-z]}
  local efi_dev=${root_dev/%$part_num/$EFI_NUM}
  log "update kernel from root_dev:$root_dev to efi_dev:$efi_dev"
  switch_kernel $(get_mp_by_device $efi_dev) $(get_mp_by_device $root_dev) $part_num
  release_mount
}
