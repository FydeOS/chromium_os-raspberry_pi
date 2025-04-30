# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="7"

DESCRIPTION="empty project"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="kiosk_demo fyde_extension"

RDEPEND="
  chromeos-base/auto-expand-partition
  chromeos-base/power_wash_command
  chromeos-base/fyde-chromedev-flags
  kiosk_demo? ( chromeos-base/fyde-kiosk-demo )
  fyde_extension? ( chromeos-base/fyde-shell-daemon-bin )
  chromeos-base/edit-pi-config
"

DEPEND="${RDEPEND}"
