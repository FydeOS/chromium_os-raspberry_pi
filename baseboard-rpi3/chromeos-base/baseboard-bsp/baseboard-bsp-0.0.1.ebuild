# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  chromeos-base/rpi-boot-bin
  chromeos-base/rpi-firmware
  sys-apps/haveged
"

DEPEND="${RDEPEND}"

S=$WORKDIR

src_install() {
  insinto /etc
  doins -r ${FILESDIR}/selinux
}
