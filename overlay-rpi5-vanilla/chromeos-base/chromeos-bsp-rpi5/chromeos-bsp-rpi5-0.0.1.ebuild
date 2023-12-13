# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="7"
inherit udev
DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  chromeos-base/device-appid
  x11-libs/libva
"

DEPEND="${RDEPEND}"

S=${FILESDIR}

src_install() {
  udev_dorules udev/10-vchiq-permissions.rules
  udev_dorules udev/50-media.rules
  insinto /firmware/rpi
  doins kernel-config/*
}
