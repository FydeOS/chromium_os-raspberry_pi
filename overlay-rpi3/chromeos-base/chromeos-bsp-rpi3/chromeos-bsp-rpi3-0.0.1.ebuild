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

RDEPEND="
    chromeos-base/rpi-boot-bin
    chromeos-base/rpi-firmware
    chromeos-base/auto-expand-partition
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
  doins "${FILESDIR}/audio/force_audio_output_to_headphones.conf"
  insinto /firmware/rpi
  doins "${FILESDIR}/kernel-config"/*.txt
}
