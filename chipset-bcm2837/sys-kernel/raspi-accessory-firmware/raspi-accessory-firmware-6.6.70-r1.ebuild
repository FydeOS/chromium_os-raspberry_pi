# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="7"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S="$WORKDIR"

src_unpack() {
  unpack ${FILESDIR}/${P}.tar.gz
}

src_install() {
  insinto /lib
  doins -r firmware
}
