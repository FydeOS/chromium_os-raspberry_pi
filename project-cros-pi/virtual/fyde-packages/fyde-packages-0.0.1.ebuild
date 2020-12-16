# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
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
