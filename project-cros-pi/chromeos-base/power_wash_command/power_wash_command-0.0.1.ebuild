# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="4"

DESCRIPTION="Add powerwash command shortcut 'clobber' to usr/local/sbin"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

src_install() {
  exeinto /usr/sbin
  doexe ${FILESDIR}/clobber 
}
