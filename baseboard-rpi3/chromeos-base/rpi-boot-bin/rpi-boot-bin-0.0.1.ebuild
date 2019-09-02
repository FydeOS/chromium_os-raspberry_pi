# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"
EGIT_REPO_URI="https://github.com/FydeOS/rpi-boot-bin.git"

inherit git-r3
DESCRIPTION="rpi boot bin files"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
  insinto /firmware/rpi
  doins -r "${S}"/*
}
