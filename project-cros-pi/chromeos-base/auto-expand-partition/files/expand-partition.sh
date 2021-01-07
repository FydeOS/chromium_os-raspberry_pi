#!/bin/sh
VERSION="1.0.1"

print_usage() {
  script=$(basename $0)
  echo "$script version:${VERSION} (c) 2020 Fyde Innovations"
  echo "  Usage: $script -d | --dst <target disk partition>
  Example: $script -d /dev/sda1
  This script will expand the target partition with the available empty disk space."  
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

expand_partition() {
  local part=$1
  local disk=$(parse_disk_dev $part)
  local partnum=$(parse_partition_num $part)
  local first_sec=$(cgpt show -i ${partnum} -b ${disk})
  local last_sec=$(cgpt show ${disk}| grep "Sec GPT table" | awk '{print $1}')
  local target_size=$((${last_sec}-${first_sec}-64))
  target_size=$((${target_size}/4*4))
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
