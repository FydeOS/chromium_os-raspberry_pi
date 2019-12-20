# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"
EGIT_REPO_URI="https://github.com/FydeOS/kiosk-demo-app.git"

inherit git-r3
DESCRIPTION="demo app for fyde kiosk"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
  insinto /usr/local/share/kiosk_app
  doins ${FILESDIR}/config.json
  insinto /usr/local/share/kiosk_app/kiosk-demo-app
  doins -r *  
}
