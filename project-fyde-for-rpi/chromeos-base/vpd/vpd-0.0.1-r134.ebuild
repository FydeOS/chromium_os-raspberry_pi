# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
CROS_WORKON_COMMIT="fabe3f4cc2204755d26ff611a1631fd51c8b0fa6"
CROS_WORKON_TREE="e5239bf292c078381e7d19833a31752f0f72f5df"
CROS_WORKON_PROJECT="chromiumos/platform/vpd"

inherit cros-workon systemd

DESCRIPTION="ChromeOS vital product data utilities"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="static systemd"

# util-linux is for libuuid.
DEPEND="sys-apps/util-linux"
# shflags for dump_vpd_log.
# chromeos-activate-date for ActivateDate upstart and script.
RDEPEND="
	sys-apps/flashrom
	dev-util/shflags
	virtual/chromeos-activate-date
  !chromeos-base/vpd-info-append
	"

FYDEOS_DEFAULT_LOCALE="en-US"
FYDEOS_DEFAULT_TIMEZONE="US/Pacific"
FYDEOS_DEFAULT_REGION="en-US"
VPD_TEMPLATE="oem_licence.tmp"

src_prepare() {
  default
  epatch ${FILESDIR}/*.patch
  cp ${FILESDIR}/${VPD_TEMPLATE} ${S}
}

src_configure() {
	cros-workon_src_configure
}

count_chars() {
  printf $1 | wc -c  
}

src_compile() {
	tc-export CC
	use static && append-ldflags -static
	emake all
  local locale=${FYDEOS_LOCALE:-`echo $FYDEOS_DEFAULT_LOCALE`}
  local timezone=${FYDEOS_TIMEZONE:-`echo $FYDEOS_DEFAULT_TIMEZONE`}
  local region=${FYDEOS_REGION:-`echo $FYDEOS_DEFAULT_REGION`}
  ${FILESDIR}/vpd -i RO_VPD -f ${VPD_TEMPLATE} \
    -p $(count_chars $locale) -s "initial_locale=${locale}" \
    -p $(count_chars $timezone) -s "initial_timezone=${timezone}" \
    -p $(count_chars $region) -s "region=${region}"
}

src_install() {
	# This target list should be architecture specific
	# (no ACPI stuff on ARM for instance)
	dosbin vpd vpd_s
	dosbin util/check_rw_vpd util/dump_vpd_log util/update_rw_vpd
	dosbin util/vpd_get_value

	# install the init script
	if use systemd; then
		systemd_dounit init/vpd-log.service
		systemd_enable_service boot-services.target vpd-log.service
	else
		insinto /etc/init
		doins init/check-rw-vpd.conf
		doins init/vpd-log.conf
    doins ${FILESDIR}/check_serial_number.conf
	fi
  insinto /usr/share/oem
  newins ${VPD_TEMPLATE} .oem_licence
  insinto /usr/share/cros/init
  doins ${FILESDIR}/check_serial_number.sh
}

src_test() {
	if ! use x86 && ! use amd64; then
		ewarn "Skipping unittests for non-x86 arches"
		return
	fi
	emake test
}
