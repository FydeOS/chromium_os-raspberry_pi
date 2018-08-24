# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"
inherit udev
DESCRIPTION="drivers, config files for rpi3"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="chromeos-base/rpi-boot-bin"

DEPEND="${RDEPEND}"
S=${WORKDIR}

src_install() {
  udev_dorules "${FILESDIR}/udev/10-vchiq-permissions.rules"
  insinto /lib/firmware
  doins -r "${FILESDIR}/brcm"
  insinto /etc/init
  doins "${FILESDIR}/bt/bluetooth_uart.conf"
  doins "${FILESDIR}/bt/console-ttyAMA0.override"
  insinto /firmware/rpi
  doins "${FILESDIR}/kernel-config"/*.txt
}
