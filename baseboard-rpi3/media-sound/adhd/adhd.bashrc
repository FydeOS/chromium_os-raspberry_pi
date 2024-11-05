if [ $PV != "9999" ]; then
PATCHES=(
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/fix_brcm_snd_issue.patch
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/fix_default_card.patch
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/fix_rpi_hdmi_iec958.patch
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/fix_hdmi_close_delay.patch
)
fi
