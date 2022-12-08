# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# unset -f cros_post_src_install_openfyde_mark_clean_overlay
unset -f cros_pre_src_prepare_openfyde_patches

cros_post_src_install_openfyde_cros_pi_hook() {
  exeinto /usr/sbin
  doexe ${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/switch_root.sh
  doexe ${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/update_kernel.sh
  insinto /usr/share/cros
  doins ${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/update_kernel_lib.sh
}

cros_pre_src_prepare_openfyde_cros_pi_patches() {
  epatch ${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/chromeos-install.patch
  epatch ${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/postinst.patch
}
