# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=4
CROS_WORKON_PROJECT="chromiumos/third_party/adhd"
CROS_WORKON_LOCALNAME="adhd"
CROS_WORKON_USE_VCSID=1

inherit toolchain-funcs autotools cros-fuzzer cros-sanitizers cros-workon systemd user libchrome-version

DESCRIPTION="Google A/V Daemon"
HOMEPAGE="http://www.chromium.org"
SRC_URI=""
LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
IUSE="asan +cras-apm fuzzer selinux systemd unibuild"

RDEPEND=">=media-libs/alsa-lib-1.0.27
	!<media-libs/alsa-lib-1.1.6-r3
	media-sound/alsa-utils
	media-plugins/alsa-plugins
	media-libs/sbc
	media-libs/speex
	cras-apm? ( media-libs/webrtc-apm )
	dev-libs/iniparser
	>=sys-apps/dbus-1.4.12
	dev-libs/libpthread-stubs
	virtual/udev
	unibuild? ( chromeos-base/chromeos-config )
	!<=chromeos-base/audioconfig-0.0.1-r1
	chromeos-base/chromeos-config-tools
	chromeos-base/metrics
	selinux? ( sys-libs/libselinux )"
DEPEND="${RDEPEND}
	media-libs/ladspa-sdk
	media-sound/cras_rust"

check_format_error() {
	local file
	local files_need_format=()
	einfo "Running format checks for ADHD .c, .cc and .h files"
	while read -r -d $'\0' file; do
		if ! cmp <(clang-format -style=file "${file}") "${file}"
		then
			files_need_format+=( "${file}" )
		fi
	done< <(find . \( -name "*.c" -o -name "*.cc" -o -name "*.h" \) \
		-print0)

	if [[ "${#files_need_format[@]}" != "0" ]]; then
		eerror "The following files have formatting errors:"
		eerror "${files_need_format[*]}"
		eerror "You can run \"clang-format -i -style=file" \
			"${files_need_format[*]}\"" \
			"under chromiumos/src/third_party/adhd to fix them."
		return 1
	fi
	einfo "    All files are well formatted."
	return 0
}

src_prepare() {
	cd cras
	eautoreconf
}

src_configure() {
	sanitizers-setup-env
	if use amd64 ; then
		export FUZZER_LDFLAGS="-fsanitize=fuzzer"
	fi

	cd cras
	# Disable external libraries for fuzzers.
	if use fuzzer ; then
		# Disable "gc-sections" for fuzzer builds, https://crbug.com/1026125 .
		append-ldflags "-Wl,--no-gc-sections"
		cros-workon_src_configure \
			$(use_enable cras-apm webrtc-apm) \
			$(use_enable amd64 fuzzer)
	else
		cros-workon_src_configure $(use_enable selinux) \
			$(use_enable cras-apm webrtc-apm) \
			--enable-metrics \
			$(use_enable amd64 fuzzer)
	fi
}

src_compile() {
	emake CC="$(tc-getCC)" || die "Unable to build ADHD"
}

src_test() {
	check_format_error || die "Format check failed"
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

	# Install seccomp policy file.
	insinto /usr/share/policy
	newins "seccomp/cras-seccomp-${ARCH}.policy" cras-seccomp.policy

	# Install asound.conf for CRAS alsa plugin
	insinto /etc
	doins "${FILESDIR}"/asound.conf

	# Install fuzzer binary
	fuzzer_install "${S}/OWNERS" cras/src/cras_rclient_message_fuzzer
}

pkg_preinst() {
	enewuser "cras"
	enewgroup "cras"
}
