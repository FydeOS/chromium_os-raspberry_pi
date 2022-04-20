# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="5"
EGIT_REPO_URI="https://gitee.com/openFyde/rpi-boot-bin.git"

inherit git-r3
DESCRIPTION="Raspberry Pi boot binary files"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
  insinto /firmware/rpi
  doins -r "${S}"/*
}
