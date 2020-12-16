#!/bin/sh
OEM_PATH=/usr/share/oem
LICENCE=${OEM_PATH}/.oem_licence
NET_NODE=/sys/class/net
LAN_MAC_NODE=$NET_NODE/eth0/address
WLAN_MAC_NODE=$NET_NODE/wlan0/address

die() {
  logger -t "${JOB}" "Error:" $@
  exit 1 
}

get_system_mac() {
  local mac

  # On the first boot, the upstart service machine-info which will call this script starts so early
  # that the NIC drivers may not even loaded, so it failed to get a mac address. This is to workaround
  # that issue, by keep trying for about 1min until get one. This does not impact subsequential boots
  # as the mac is stored.
  for i in $(seq 20); do
    if [ -e $LAN_MAC_NODE ]; then
      mac=$(cat $LAN_MAC_NODE)
    elif [ -e $WLAN_MAC_NODE ]; then
      mac=$(cat $WLAN_MAC_NODE)
    else
      mac=$(ifconfig -a | awk '/ether/ {print $2;exit}')
    fi

    if [ -n "$mac" ]; then
      echo $mac
      break
    fi

    logger -t "$JOB" "Cannot get mac, maybe NIC driver is not ready yet, waiting to retry"
    sleep 1s
  done
}

is_booting_from_usb() {
  [ -n "$(udevadm info $(rootdev -d) | grep ID_BUS |grep usb)" ]  
}

remount_oem_writable() {
  mount -o remount,rw "$OEM_PATH"
}

remount_oem_readonly() {
  mount -o remount,ro "$OEM_PATH"
}

count_chars() {
  printf $1 | wc -c
}

update_serial_number() {
	local serial=$1
  vpd -i RO_VPD  \
    -p $(count_chars $serial) -s "serial_number=${serial}"
  dump_vpd_log --force
}

check_vpd() {
  if [ ! -s "${LICENCE}" ]; then
    cat /usr/share/cros/init/vpd.gz | gunzip > ${LICENCE}
  fi  
}

check_serial_number() {
  local serial=$(vpd -i RO_VPD -g serial_number 2>/dev/null)
  local mac_serial=$(get_system_mac | sed "s/://g")
  if [ -z "$mac_serial" ]; then 
    exit 1
  fi
  if [ "$serial" != "$mac_serial" ]; then
    if is_booting_from_usb; then
      update_serial_number $mac_serial
    elif [ -z "$serial" ]; then
      update_serial_number $mac_serial
    fi
  fi
}

remount_oem_writable || die "Remount OEM partition failed"
check_vpd || die "Cann't init vpd system"
check_serial_number
remount_oem_readonly
