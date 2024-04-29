#!/bin/bash

cros_pre_src_prepare_openfyde_cros_pi_patches() {
  if [ $PV != '9999' ]; then
    eapply -p2 "${OPENFYDE_CROS_PI_BASHRC_FILESDIR}/002-fix-rpi-camera-bind-mount-issue.patch"
  fi
}
