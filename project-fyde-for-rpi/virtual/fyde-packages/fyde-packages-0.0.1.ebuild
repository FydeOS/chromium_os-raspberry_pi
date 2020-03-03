# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="kiosk_demo widevine fyde_extension"

RDEPEND="
  chromeos-base/auto-expand-partition
  chromeos-base/power_wash_command
  chromeos-base/fyde-chromedev-flags
  widevine? ( chromeos-base/libwidevine )
  kiosk_demo? ( chromeos-base/fyde-kiosk-demo )
  fyde_extension? ( chromeos-base/fyde-shell-daemon-bin )
"

DEPEND="${RDEPEND}"
