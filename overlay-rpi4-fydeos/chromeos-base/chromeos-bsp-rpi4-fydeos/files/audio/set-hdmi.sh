#/bin/bash
cras_client=/usr/bin/cras_test_client
plug_devs=(e9849cd9)
unplug_devs=(99dc7b5c 595f1baf)

set_state(){
  local dev=$1
  local state=$2
  ${cras_client} --plug "${dev}":${state}
}

plug_dev(){
  local dev=$1
  set_state $dev 1
  logger -t "rpi4-hdmi" "set ${dev} plugged"
}

unplug_dev(){
  local dev=$1
  set_state $dev 0
  logger -t "rpi4-hdmi" "set ${dev} unplugged"
}

unplug_devs(){
  for id in "${unplug_devs[@]}";do
    local dev=$(${cras_client} | grep $id | awk '{print $2}')
    unplug_dev $dev
  done
}

plug_devs(){
  for id in "${plug_devs[@]}";do
    local dev=$(${cras_client} | grep $id | awk '{print $2}')
    plug_dev $dev
  done
}

plug_devs
unplug_devs
