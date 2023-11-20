# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="7"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="chromeos-base/fydeos-default-chromedev-flags"

DEPEND="${RDEPEND}"

S=${FILESDIR}

src_install() {
  insinto /etc/init
  doins init/*
  insinto /lib/udev/rules.d
  doins rules/*
}
