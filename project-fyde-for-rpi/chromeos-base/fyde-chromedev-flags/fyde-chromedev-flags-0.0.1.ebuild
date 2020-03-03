# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="4"
inherit chrome-dev-flag 
DESCRIPTION="append chrome command line flags"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
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
