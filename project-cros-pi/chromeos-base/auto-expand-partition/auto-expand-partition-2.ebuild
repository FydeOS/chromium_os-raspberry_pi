# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI=7

DESCRIPTION="Auto expand stateful partition on first boot"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	sys-apps/gptfdisk[-ncurses]
"

S=${WORKDIR}

src_install() {
	# Install upstart service
  exeinto "/usr/sbin"
  doexe ${FILESDIR}/expand-partition.sh
	insinto "/etc/init"
	doins ${FILESDIR}/auto-expand-partition.conf
}
