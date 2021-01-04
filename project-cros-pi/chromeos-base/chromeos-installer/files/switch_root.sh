#!/bin/bash
part_num=$1
disk_dev=$2
kernelA=2
kernelB=4
rootA=3
rootB=5
CMDFILE="cmdline.txt"

. /usr/share/cros/update_kernel_lib.sh


get_part_priority() {
  local part_num=$1
  cgpt show -i $part_num -P $disk_dev
}

determin_root_num() {
  local priorityA=$(get_part_priority $kernelA)
  local priorityB=$(get_part_priority $kernelB)
  if [ "$priorityA" -ge "$priorityB" ]; then
    echo $rootA
  else
    echo $rootB
  fi
}


help() {
  echo "$0 [root_partition_num] [disk_dev]"
  echo "example 1: $0 3 /dev/sda :means load /dev/sda3 as root at next booting" 
  echo "example 2: $0 3 :means load current device partition 3 as root at next booting"
  echo "example 3: $0 :means switch rootfs by ChromeOS rules "
}

die() {
  echo $@
  help
  exit 1
}

get_uuid() {
  local part_num=$1
  local disk_dev=$2
  cgpt show -i $part_num -u $disk_dev 
}

check_var() {
  local part_num=$1
  local disk_dev=$2
  if [ -z "$part_num" ]; then
    die "need one part_num."
  fi
  if [ ! -b ${disk_dev} ]; then
    die "${disk_dev} does not exist!"
  fi
  get_uuid $part_num $disk_dev 2>&1 1>/dev/null || die "Can not get real partition uuid"  
}

modify_root() {
  local cmdfile=$1
  local root_uuid=$2
  sed -i "s|[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*-[[:alnum:]]*|${root_uuid}|g" $cmdfile
  sync $cmdfile
}

main() {
 local part_num=$1
 local disk_dev=$2
 [ -z "${disk_dev}" ] && disk_dev=$(rootdev -d)
 [ -z "${part_num}" ] && part_num=$(determin_root_num)
 check_var $part_num $disk_dev
 local tmpdir=$(mktemp -d) 
 local root_uuid=$(get_uuid $part_num $disk_dev) 
 local efi_dev=
 if [[ $disk_dev =~ [a-z]$ ]]; then
   efi_dev=${disk_dev}${EFI_NUM}
 else
   efi_dev=${disk_dev}p${EFI_NUM}
 fi
 local root_dev=
 if [[ $disk_dev =~ [a-z]$ ]]; then
   root_dev=${disk_dev}${part_num}
 else
   root_dev=${disk_dev}p${part_num}
 fi
 mount $efi_dev $tmpdir || die "error mounting"
 modify_root ${tmpdir}/${CMDFILE} $root_uuid || die "error when modified cmdline.txt"
 update_root_kernel $root_dev
 umount $tmpdir
 rmdir $tmpdir
}

main $@
