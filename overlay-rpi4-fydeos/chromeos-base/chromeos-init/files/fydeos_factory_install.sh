#。!/bin/bash
SELF_OEM="/usr/share/oem"
TARGET_FILE=".fydeos_factory_install"
BOARD_FILE="fydeos_board_hooks.sh"
LOG_FILE="/var/log/fydeos_factory_install.log"
SKIP_CHROMEOS_INSTALL=false
CHROMEOS_PAYLOAD_DIR="/usr/local/payload_image"

board_install_before() {
  true  
}

board_install_post() {
  true  
}

if [ -f "${SELF_OEM}/${BOARD_FILE}" ]; then
  . ${SELF_OEM}/${BOARD_FILE}
fi

log_install() {
  echo $(date +%F:%T) $@ >> $LOG_FILE
}

get_oem_dev() {
  /usr/bin/cgpt find -l OEM $1
}

mount_oem() {
  local mp=$1
  local target=$2
  [ -d $mp ] || mkdir -p $mp
  mount $(get_oem_dev $target) $mp
}

wait_for_key_to_reboot() {
  local input_char=""
  read -n 1 input_char
  sleep 3
  shutdown -P now 
}

fydeos_post_install() {
  local mp="/tmp/oem_mnt"
  local target=$1
  mount_oem $mp $target
  if [ $? -ne 0 ]; then
    log_install "mount oem error"
    return
  fi
  rm ${mp}/${TARGET_FILE}
  rm ${mp}/${BOARD_FILE} || true
  board_install_post $mp
  umount $mp
}

install() {
  local target=$1 
  local image="$(ls -t ${CHROMEOS_PAYLOAD_DIR}/*.bin 2>/dev/null | head -n1)"
  chromeos-install --payload_image "$image" --dst ${target} --yes >> $LOG_FILE
}

check_and_install() {
  local target_devs=""
  local oem_target="${SELF_OEM}/${TARGET_FILE}"
  if [ -f $oem_target ]; then
    target_devs=$(cat $oem_target)
  fi
  if [ -n "${target_devs}" ]; then
    for target_disk in $target_devs ; do
      if [ ! -w "${target_disk}" ]; then
        continue
      fi
      log_install "target file detected:$target_disk"
      chromeos-boot-alert update_firmware
      log_install "begin install"
      board_install_before $target_disk
      if $SKIP_CHROMEOS_INSTALL ; then
        return 0
      fi
      install $target_disk
      if [ $? -ne 0 ]; then
         log_install "error occured" 
         display_boot_message fydeos_install_failure 'zh-CN en'
         wait_for_key_to_reboot
         exit 1
      fi    
      log_install "end install"
      fydeos_post_install ${target_disk} 
      display_boot_message fydeos_install_success 'zh-CN en'
      wait_for_key_to_reboot
      exit 0
    done
    log_install "can't find the target disk"
    display_boot_message fydeos_target_failure 'zh-CN en'
    wait_for_key_to_reboot
    exit 1
  fi
}

log_install "check and install"
check_and_install
log_install "nothing happened"
