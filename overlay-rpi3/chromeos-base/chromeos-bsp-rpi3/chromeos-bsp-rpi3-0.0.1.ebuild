# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"
inherit udev
DESCRIPTION="drivers, config files for rpi3"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
    chromeos-base/device-appid
    chromeos-base/snd_bcm2835-spec
"

DEPEND="${RDEPEND}"
S=${WORKDIR}

src_install() {
  udev_dorules "${FILESDIR}/udev/10-vchiq-permissions.rules"
  udev_dorules "${FILESDIR}/udev/50-media.rules"
  insinto /etc/init
  doins "${FILESDIR}/bt/bluetooth_uart.conf"
  doins "${FILESDIR}/bt/console-ttyAMA0.override"
  #doins "${FILESDIR}/audio/force_audio_output_to_headphones.conf"
  insinto /usr/share/alsa/ucm
  doins -r ${FILESDIR}/audio/bcm2835\ ALSA
  doins -r ${FILESDIR}/audio/vc4-hdmi
  insinto /firmware/rpi
  doins "${FILESDIR}/kernel-config"/*.txt
}
