# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2012 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="227ffbb1e22dc5ff99ff96ef243f13eb482cc6da"
CROS_WORKON_TREE="c732df6077377143c7d5590e1b7c91c705c2ecd2"
CROS_WORKON_PROJECT="chromiumos/platform/vpd"
CROS_WORKON_LOCALNAME="platform/vpd"

inherit cros-workon systemd

DESCRIPTION="ChromeOS vital product data utilities"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/vpd/"
SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="static systemd"

# util-linux is for libuuid.
DEPEND="sys-apps/util-linux:="
# shflags for dump_vpd_log.
# chromeos-activate-date for ActivateDate upstart and script.
RDEPEND="
	sys-apps/flashrom
	dev-util/shflags
	virtual/chromeos-activate-date
	"
VPD_TEMPLATE="oem_licence.tmp"
src_compile() {
	tc-export CC
	use static && append-ldflags -static
	emake all
  cat ${FILESDIR}/${VPD_TEMPLATE} | gzip > "vpd.gz"
}

src_install() {
	# This target list should be architecture specific
	# (no ACPI stuff on ARM for instance)
	dosbin vpd vpd_s
	dosbin util/dump_vpd_log util/update_rw_vpd
	dosbin util/vpd_get_value util/vpd_icc

	# install the init script
	if use systemd; then
		systemd_dounit init/vpd-log.service
		systemd_enable_service boot-services.target vpd-log.service
	else
		insinto /etc/init
		doins init/vpd-icc.conf
		doins init/vpd-log.conf
    doins ${FILESDIR}/check_serial_number.conf
	fi
  insinto /usr/share/cros/init
  doins vpd.gz
  doins ${FILESDIR}/check_serial_number.sh
}

src_test() {
	if ! use x86 && ! use amd64; then
		ewarn "Skipping unittests for non-x86 arches"
		return
	fi
	emake test
}

src_prepare() {
  default
  eapply ${FILESDIR}/*.patch
}
