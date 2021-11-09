# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/bluez/bluez-4.99.ebuild,v 1.7 2012/04/15 16:53:41 maekke Exp $

EAPI="7"
# To support choosing between current and next versions, two cros-workon
# projects are declared. During emerge, both project sources are copied to
# their respective destination directories, and one is chosen as the
# "working directory" in src_unpack() below based on bluez-next USE flag.
CROS_WORKON_LOCALNAME=("bluez/current" "bluez/next" "bluez/upstream")
CROS_WORKON_PROJECT=("chromiumos/third_party/bluez" "chromiumos/third_party/bluez" "chromiumos/third_party/bluez")
CROS_WORKON_OPTIONAL_CHECKOUT=(
	"use !bluez-next && use !bluez-upstream"
	"use bluez-next"
	"use bluez-upstream"
)
CROS_WORKON_DESTDIR=("${S}/bluez/current" "${S}/bluez/next" "${S}/bluez/upstream")
CROS_WORKON_EGIT_BRANCH=("chromeos-5.54" "chromeos-5.54" "upstream/master")

inherit autotools multilib eutils systemd udev user libchrome cros-fuzzer cros-sanitizers cros-workon flag-o-matic

DESCRIPTION="Bluetooth Tools and System Daemons for Linux"
HOMEPAGE="http://www.bluez.org/"
#SRC_URI not defined because we get our source locally

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="~*"
IUSE="asan bluez-next bluez-upstream cups debug fuzzer hid2hci systemd readline bt_deprecated_tools"
REQUIRED_USE="?? ( bluez-next bluez-upstream )"

CDEPEND="
	>=dev-libs/glib-2.14:2=
	app-arch/bzip2:=
	sys-apps/dbus:=
	virtual/libudev:=
	cups? ( net-print/cups:= )
	readline? ( sys-libs/readline:= )
	>=chromeos-base/metrics-0.0.1-r3152:=
"
DEPEND="${CDEPEND}"

RDEPEND="${CDEPEND}
	!net-wireless/bluez-hcidump
	!net-wireless/bluez-libs
	!net-wireless/bluez-test
	!net-wireless/bluez-utils
"
BDEPEND="${CDEPEND}
	dev-util/pkgconfig:=
	sys-devel/flex:=
"

PATCHES=(
	"${FILESDIR}"/bluez-hid2hci.patch
)

DOCS=( AUTHORS ChangeLog README )

src_unpack() {
	cros-workon_src_unpack

	# Setting S has the effect of changing the temporary build directory
	# here onwards. Choose "bluez/next" or "bluez/current" subdir depending on
	# the USE flag.
	local checkout="bluez/$(usex bluez-next next $(usex bluez-upstream upstream current))"
	S+="/${checkout}"
	local version="$("${FILESDIR}"/chromeos-version.sh "${S}")"
	einfo "Using checkout ${checkout} (version ${version})"
}

src_prepare() {
	default

	eautoreconf

	if use cups; then
		sed -i \
			-e "s:cupsdir = \$(libdir)/cups:cupsdir = $(cups-config --serverbin):" \
			Makefile.tools Makefile.in || die
	fi
}

src_configure() {
	sanitizers-setup-env
	# Workaround a global-buffer-overflow warning in asan build.
	# See crbug.com/748216 for details.
	if use asan; then
		append-flags '-mllvm -asan-globals=0'
	fi

	use readline || export ac_cv_header_readline_readline_h=no

	export BASE_VER="$(libchrome_ver)"
	econf \
		--enable-tools \
		--localstatedir=/var \
		$(use_enable cups) \
		--enable-datafiles \
		$(use_enable debug) \
		--disable-test \
		--enable-library \
		--disable-systemd \
		--disable-obex \
		--enable-sixaxis \
		--disable-network \
		--disable-datafiles \
		$(use_enable fuzzer) \
		$(use_enable hid2hci) \
		$(use_enable bt_deprecated_tools deprecated)
}

src_test() {
	# TODO(armansito): Run unit tests for non-x86 platforms.
	[[ "${ARCH}" == "x86" || "${ARCH}" == "amd64" ]] && \
		emake check VERBOSE=1
}

src_install() {
	default

	dobin tools/btmgmt tools/btgatt-client tools/btgatt-server

	# Install scripts
	dobin "${FILESDIR}/dbus_send_blutooth_class.awk"
	dobin "${FILESDIR}/get_bluetooth_device_class.sh"
	dobin "${FILESDIR}/start_bluetoothd.sh"
	dobin "${FILESDIR}/start_bluetoothlog.sh"

	# Install init scripts.
	if use systemd; then
		systemd_dounit "${FILESDIR}/bluetoothd.service"
		systemd_enable_service system-services.target bluetoothd.service
		systemd_dotmpfilesd "${FILESDIR}/bluetoothd-directories.conf"
	else
		insinto /etc/init
		newins "${FILESDIR}/${PN}-upstart.conf" bluetoothd.conf
		newins "${FILESDIR}/bluetoothlog-upstart.conf" bluetoothlog.conf
	fi

	# Install D-Bus config
	insinto /etc/dbus-1/system.d
	doins "${FILESDIR}/org.bluez.conf"

	# Install udev files
	udev_dorules "${FILESDIR}/99-uhid.rules"
	udev_dorules "${FILESDIR}/99-ps3-gamepad.rules"
	udev_dorules "${FILESDIR}/99-bluetooth-quirks.rules"

	# Install the config files.
	insinto "/etc/bluetooth"
	doins "${FILESDIR}/main.conf"
	doins "${FILESDIR}/input.conf"

	# Install the fuzzer binaries.
	fuzzer_install "${S}/fuzzer/OWNERS" fuzzer/bluez_pattern_match_fuzzer
	fuzzer_install "${S}/fuzzer/OWNERS" fuzzer/bluez_pattern_new_fuzzer

	# We don't preserve /var/lib in images, so nuke anything we preseed.
	rm -rf "${D}"/var/lib/bluetooth

	rm "${D}/lib/udev/rules.d/97-bluetooth.rules"

	find "${D}" -name "*.la" -delete
}

pkg_postinst() {
	enewuser "bluetooth" "218"
	enewgroup "bluetooth" "218"

	udev_reload
}
