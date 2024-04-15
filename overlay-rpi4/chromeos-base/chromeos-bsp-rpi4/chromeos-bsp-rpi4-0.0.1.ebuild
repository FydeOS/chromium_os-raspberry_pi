# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="7"
inherit udev
DESCRIPTION="drivers, config files for Raspberry Pi 4"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD-Fyde"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
    chromeos-base/device-appid
    chromeos-base/bluetooth-input-fix
    x11-libs/libva
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
  dosym /lib/firmware /etc/firmware
}
