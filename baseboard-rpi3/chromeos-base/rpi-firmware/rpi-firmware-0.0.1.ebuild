# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="Raspberry Pi firmware"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

src_install() {
  insinto /lib
  doins -r "${FILESDIR}/firmware"
}
