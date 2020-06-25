# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
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
