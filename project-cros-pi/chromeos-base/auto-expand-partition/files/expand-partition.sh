#!/bin/sh
VERSION="1.0.1"

print_usage() {
  script=$(basename $0)
  echo "$script version:${VERSION} (c) 2020 Fyde Innovations"
  echo "  Usage: $script -d | --dst <target disk partition>
  Example: $script -d /dev/sda1
  This script will expand the target partition of removable disk with the available empty disk space."
  exit
}

# get disk device from partition device.
# para $1: /dev/sda1 return /dev/sda    $1: /dev/mmcblk0p3 return /dev/mmcblk0
parse_disk_dev() {
    local disk=$1
    local disk=$(echo $1 | sed 's/[0-9_]*$//')
    if [ -z "$(echo $disk | grep '/sd')" ]; then
        disk=${disk%p}
    fi
    echo $disk
}

# $1 as /dev/mmcblk0p12 return 12
parse_partition_num() {
    local dev=$1
    echo ${dev##*[a-z]}
}

is_disk() {
 [ -n "$(lsblk -l -o name,type |grep disk| grep $(basename $1))" ]
}

is_partition() {
 local disk=$(parse_disk_dev $1)
 echo $disk
 if ! is_disk $disk; then
   false
   return
 fi
 local partnum=$(parse_partition_num $1)
 echo $partnum
 [ -n "$(partx -s -o nr -n ${partnum}:${partnum} -g $disk)" ]
}

# Size of a block device in 512-byte sectors.
# NB: `partx -b -o size` reports bytes, not sectors, so it must not be used here.
dev_sectors() {
  if [ -x /sbin/blockdev ]; then
    /sbin/blockdev --getsz "$1" 2>/dev/null && return
  fi
  cat "/sys/class/block/$(basename "$1")/size" 2>/dev/null
}

expand_partition() {
  local part=$1
  local disk=$(parse_disk_dev $part)
  local partnum=$(parse_partition_num $part)
  local first_sec=$(cgpt show -i ${partnum} -b ${disk})
  local last_sec=$(cgpt show ${disk}| grep "Sec GPT table" | awk '{print $1}')
  local cur_sec=$(dev_sectors $part)

  # Bail out before doing arithmetic on empty values, which would otherwise
  # abort the script with a shell syntax error.
  if [ -z "$first_sec" ] || [ -z "$last_sec" ] || [ -z "$cur_sec" ]; then
    echo "Cannot determine geometry for $part (first='$first_sec' last='$last_sec' cur='$cur_sec');"
    echo "refusing to modify the partition table."
    return 0
  fi

  local target_size=$((${last_sec}-${first_sec}-64))
  target_size=$((${target_size}/4*4))

  # Never shrink a partition.
  #
  # cgpt will happily record a size smaller than the filesystem already living
  # in the partition, and resize2fs cannot shrink a mounted filesystem, so the
  # shrink silently sticks. The next boot then fails with
  #   EXT4-fs (sdaN): bad geometry: block count X exceeds size of device (Y)
  # which fails the stateful mount and sends the device into clobber/powerwash.
  #
  # This happens whenever there is no room behind the partition to grow into --
  # e.g. an image written to a disk barely larger than itself.
  if [ "$target_size" -le "$cur_sec" ]; then
    echo "No free space behind $part (current ${cur_sec} sectors, computed ${target_size}); nothing to expand."
    return 0
  fi

  echo "Expanding $part: ${cur_sec} -> ${target_size} sectors"
  echo "Check disk:$disk partition table..."
  sgdisk -e $disk
  echo "Down"
  echo "Modify partition $partnum..."
  cgpt add -i $partnum -s ${target_size} $disk
  echo "Down"
  echo "Notify kernel..."
  partx -u $part
  echo "Down"
  echo "Resize filesystem on partition..."
  sync
  resize2fs $part
  echo "Down"
}

target_partition=""

[ $# -le 1 ] && print_usage

while [ $# -gt 1 ]; do
        opt=$1

        case $opt in
                -d | --dst )
                        target_partition=$2
                        break
                        ;;
                * )
                        print_usage
                        ;;
        esac

done
echo $target_partition
if is_partition $target_partition; then
  expand_partition $target_partition
else
  print_usage 
fi
