# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="+kiosk_demo"

RDEPEND="
  kiosk_demo? ( chromeos-base/fyde-kiosk-demo
                chromeos-base/power_wash_command )
"

DEPEND="${RDEPEND}"
