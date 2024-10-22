baseboard_rpi3_stack_bashrc() {
  local cfg cfgd

  cfgd="/mnt/host/source/src/overlays/baseboard-rpi3/${CATEGORY}/${PN}"
  for cfg in ${PN} ${P} ${PF} ; do
    cfg="${cfgd}/${cfg}.bashrc"
    [[ -f ${cfg} ]] && . "${cfg}"
  done

  export BASEBOARD_RPI_BASHRC_FILESDIR="${cfgd}/files"
}

baseboard_rpi3_stack_bashrc
