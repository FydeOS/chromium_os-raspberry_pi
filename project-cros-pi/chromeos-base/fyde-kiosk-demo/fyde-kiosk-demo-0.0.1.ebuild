# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="7"
EGIT_REPO_URI="https://github.com/FydeOS/kiosk-demo-app.git"

inherit git-r3
DESCRIPTION="Install demo app for Chromium OS for Raspberry Pi kiosk mode"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
  insinto /usr/local/share/kiosk_app
  doins ${FILESDIR}/config.json
  insinto /etc/init
  doins ${FILESDIR}/system-services.override
  insinto /usr/local/share/kiosk_app/kiosk-demo-app
  doins -r *  
}
