# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="4"
inherit chrome-dev-flag 
DESCRIPTION="append chrome commandline flags"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="kiosk_demo"

S=${WORKDIR}

CHROME_DEV_FLAGS="${CHROME_DEV_FLAGS}"

src_prepare() {
    if use kiosk_demo; then
      CHROME_DEV_FLAGS="${CHROME_DEV_FLAGS} --force-kiosk-mode"
    fi
}
