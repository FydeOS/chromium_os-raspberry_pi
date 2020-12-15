# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="bcm2835 chip related configuration files"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S=$WORKDIR

src_install() {
  #insinto /etc/modprobe.d
  #doins ${FILESDIR}/snd_bcm2835.conf  
  insinto /etc/init
  doins "${FILESDIR}/force_audio_output_to_headphones.conf"
}
