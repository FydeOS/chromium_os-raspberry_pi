# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"
inherit udev
DESCRIPTION="drivers, config files for Raspberry Pi 4"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
    chromeos-base/arc-user-env
    chromeos-base/device-appid
"

DEPEND="${RDEPEND}"
S=${WORKDIR}

src_install() {
  udev_dorules "${FILESDIR}/udev/10-vchiq-permissions.rules"
  udev_dorules "${FILESDIR}/udev/50-media.rules"
  insinto /etc/init
  doins "${FILESDIR}/bt/bluetooth_uart.conf"
  doins "${FILESDIR}/bt/console-ttyAMA0.override"
  doins "${FILESDIR}"/audio/rpi4-hdmi.conf
  insinto /firmware/rpi
  doins "${FILESDIR}/kernel-config"/*
  exeinto /usr/share/cros/init
  doexe "${FILESDIR}"/audio/set-hdmi.sh
  insinto /etc/chromium/policies/managed
  doins ${FILESDIR}/power_policy/power.json
  insinto /etc
  doins ${FILESDIR}/etc/hardware_features.xml
}
