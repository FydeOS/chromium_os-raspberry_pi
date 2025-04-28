# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="7"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""
SRC_URI="https://github.com/raspberrypi/firmware/releases/download/1.20250326/raspi-firmware_1.20250326.orig.tar.xz"
RESTRICT="mirror"

RDEPEND="!chromeos-base/rpi-boot-bin"

DEPEND="${RDEPEND}"

src_install() {
  insinto /firmware/rpi
  doins boot/*
}
