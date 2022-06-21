openfyde_cros_pi_stack_bashrc() {
  local cfg cfgd

  cfgd="/mnt/host/source/src/overlays/project-cros-pi/${CATEGORY}/${PN}"
  for cfg in ${PN} ${P} ${PF} ; do
    cfg="${cfgd}/${cfg}.bashrc"
    [[ -f ${cfg} ]] && . "${cfg}"
  done

  export OPENFYDE_CROS_PI_BASHRC_FILESDIR="${cfgd}/files"
}

openfyde_cros_pi_stack_bashrc
