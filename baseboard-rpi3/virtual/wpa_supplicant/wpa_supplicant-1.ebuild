# Copyright 2020 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Virtual to select between different wpa_supplicant revisions"
HOMEPAGE=""
SRC_URI=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"
IUSE=""
RDEPEND="
	!net-wireless/wpa_supplicant-cros:=[dbus]
	!net-wireless/wpa_supplicant-2_9
	!net-wireless/wpa_supplicant-2_8
	net-wireless/wpa_supplicant
"
DEPEND="${RDEPEND}"
