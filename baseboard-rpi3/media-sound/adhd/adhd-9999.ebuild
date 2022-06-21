# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7
CROS_WORKON_PROJECT="chromiumos/third_party/adhd"
CROS_WORKON_LOCALNAME="adhd"
CROS_WORKON_USE_VCSID=1

inherit toolchain-funcs autotools cros-fuzzer cros-sanitizers cros-workon
inherit cros-unibuild systemd user libchrome-version

DESCRIPTION="Google A/V Daemon"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/adhd/"
SRC_URI=""
LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE="asan +cras-apm fuzzer selinux systemd"

COMMON_DEPEND="
	>=chromeos-base/metrics-0.0.1-r3152:=
	dev-libs/iniparser:=
	cras-apm? ( media-libs/webrtc-apm:= )
	>=media-libs/alsa-lib-1.1.6-r3:=
	media-libs/ladspa-sdk:=
	media-libs/sbc:=
	media-libs/speex:=
	>=sys-apps/dbus-1.4.12:=
	selinux? ( sys-libs/libselinux:= )
	virtual/udev:=
"

RDEPEND="
	${COMMON_DEPEND}
	media-sound/alsa-utils
	media-plugins/alsa-plugins
	chromeos-base/chromeos-config-tools
	chromeos-base/featured
"

DEPEND="
	${COMMON_DEPEND}
	dev-libs/libpthread-stubs:=
	media-sound/cras_rust:=
"

src_prepare() {
	cd cras
	eautoreconf
	default
}

src_configure() {
	cros_optimize_package_for_speed
	sanitizers-setup-env
	if use amd64 ; then
		export FUZZER_LDFLAGS="-fsanitize=fuzzer"
	fi

	cd cras
	# Disable external libraries for fuzzers.
	if use fuzzer ; then
		# Disable "gc-sections" for fuzzer builds, https://crbug.com/1026125 .
		append-ldflags "-Wl,--no-gc-sections"
		econf $(use_enable cras-apm webrtc-apm) \
			--with-system-cras-rust \
			$(use_enable amd64 fuzzer)
	else
		econf $(use_enable selinux) \
			$(use_enable cras-apm webrtc-apm) \
			--enable-hats \
			--enable-metrics \
			--with-system-cras-rust \
			$(use_enable amd64 fuzzer) \
			BASE_VER="$(libchrome_ver)"
	fi
}

src_compile() {
	emake CC="$(tc-getCC)" || die "Unable to build ADHD"
}

src_test() {
	if ! use x86 && ! use amd64 ; then
		elog "Skipping unit tests on non-x86 platform"
	else
		cd cras
		# This is an ugly hack that happens to work, but should not be copied.
		LD_LIBRARY_PATH="${SYSROOT}/usr/$(get_libdir)" \
		emake check
	fi
}

src_install() {
	emake DESTDIR="${D}" SYSTEMD="$(usex systemd)" install

	# install common ucm config files.
	insinto /usr/share/alsa/ucm
	doins -r ucm-config/for_all_boards/*

	# install common cras config files.
	insinto /etc/cras
	doins -r cras-config/for_all_boards/*

	# install dbus config allowing cras access
	insinto /etc/dbus-1/system.d
	doins dbus-config/org.chromium.cras.conf

	# Install D-Bus XML files.
	insinto /usr/share/dbus-1/interfaces/
	doins cras/dbus_bindings/*.xml

	# Install seccomp policy file.
	insinto /usr/share/policy
	newins "seccomp/cras-seccomp-${ARCH}.policy" cras-seccomp.policy

	# Install asound.conf for CRAS alsa plugin
	insinto /etc
	doins "${FILESDIR}"/asound.conf

	if use fuzzer ; then
		# Install example dsp.ini file for fuzzer
		insinto /etc/cras
		doins cras-config/dsp.ini.sample
		# Install fuzzer binary
		fuzzer_install "${S}/OWNERS" cras/src/cras_rclient_message_fuzzer
		local fuzzer_component_id="777118"
		fuzzer_install "${S}/OWNERS" cras/src/cras_hfp_slc_fuzzer \
			--dict "${S}/cras/src/fuzz/cras_hfp_slc.dict" \
			--comp "${fuzzer_component_id}"
	fi
}

pkg_preinst() {
	enewuser "cras"
	enewgroup "cras"
	enewgroup "bluetooth-audio"
}
