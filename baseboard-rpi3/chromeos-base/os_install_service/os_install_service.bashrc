cros_pre_src_install_rpi_install_service() {
    touch "${S}"/conf/os_install_service-seccomp-${ARCH}.policy
}

cros_post_src_install_rpi_install_service() {
    rm /usr/share/policy/os_install_service-seccomp.policy
}

PATCHES=(
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/0001-add-args-for-chromeos-install-to-make-it-work-on-pi.patch
  ${BASEBOARD_RPI_BASHRC_FILESDIR}/0002-remove-os_install_service-seccomp-policy-for-minijail.patch
)
