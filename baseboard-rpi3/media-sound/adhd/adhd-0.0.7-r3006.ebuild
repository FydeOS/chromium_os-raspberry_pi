# Copyright 2012 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7
CROS_WORKON_COMMIT="4cb0c5189686d5a55f37f222c53127b160d10686"
CROS_WORKON_TREE="3ca74efc0023ad04ad93e88bc50e7009703d03f3"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_PROJECT="chromiumos/third_party/adhd"
CROS_WORKON_LOCALNAME="adhd"
CROS_WORKON_USE_VCSID=1

inherit toolchain-funcs autotools cros-bazel cros-fuzzer cros-sanitizers cros-workon
inherit cros-unibuild systemd user

DESCRIPTION="Google A/V Daemon"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/adhd/"

# The URIs are separated into two parts.
# 1. Explicit dependencies listed in WORKSPACE.bazel.
#    These can be generated with:
#    bazel build //repositories/http_archive_deps:bazel_external_uris
# 2. Implicit dependencies of Bazel. Manitained manually.
bazel_external_uris="
	http://ndevilla.free.fr/iniparser/iniparser-3.1.tar.gz -> iniparser-3.1.tar.gz
	https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz -> bazelbuild-bazel-skylib-1.4.1.tar.gz
	https://github.com/bazelbuild/rules_cc/releases/download/0.0.6/rules_cc-0.0.6.tar.gz -> bazelbuild-rules_cc-0.0.6.tar.gz
	https://github.com/bazelbuild/rules_rust/releases/download/0.17.0/rules_rust-v0.17.0.tar.gz -> bazelbuild-rules_rust-v0.17.0.tar.gz
	https://github.com/google/benchmark/archive/refs/tags/v1.7.1.tar.gz -> google-benchmark-v1.7.1.tar.gz
	https://github.com/hedronvision/bazel-compile-commands-extractor/archive/0197fc673a1a6035078ac7790318659d7442e27e.tar.gz -> hedronvision-bazel-compile-commands-extractor-0197fc673a1a6035078ac7790318659d7442e27e.tar.gz

	https://github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip -> bazelbuild-rules_java-7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip
	https://mirror.bazel.build/bazel_coverage_output_generator/releases/coverage_output_generator-v2.5.zip -> coverage_output_generator-v2.5.zip
	https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz -> bazelbuild-rules_proto-7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz
	https://mirror.bazel.build/openjdk/azul-zulu11.50.19-ca-jdk11.0.12/zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz -> bazel-zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz
	https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools-v11.7.1.zip
	https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools_linux-v11.7.1.zip
"
SRC_URI="${bazel_external_uris}"
LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="asan +cras-apm cras-debug cras-ml dlc featured fuzzer selinux systemd"

COMMON_DEPEND="
	chromeos-base/chromeos-config-tools:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	dev-libs/iniparser:=
	cras-apm? ( media-libs/webrtc-apm:= )
	>=media-libs/alsa-lib-1.1.6-r3:=
	media-libs/ladspa-sdk:=
	media-libs/sbc:=
	media-libs/speex:=
	>=media-sound/cras_rust-0.1.1:=
	cras-ml? ( sci-libs/tensorflow:= )
	>=sys-apps/dbus-1.4.12:=
	selinux? ( sys-libs/libselinux:= )
	virtual/udev:=
"

RDEPEND="
	${COMMON_DEPEND}
	media-sound/alsa-utils
	dlc? ( media-sound/sr-bt-dlc:= )
	dlc? ( virtual/chromeos-audio-nc-ap-dlc:= )
	media-plugins/alsa-plugins
	chromeos-base/chromeos-config-tools
	featured? ( chromeos-base/featured )
	!<media-sound/cras_rust-0.1.1
"

DEPEND="
	${COMMON_DEPEND}
	dev-libs/libpthread-stubs:=
"

adhd-bazel() {
	bazel_setup_bazelrc
	set -- bazel-5 --bazelrc="${T}/bazelrc" --output_user_root="$(cros-workon_get_build_dir)" "$@"
	echo "${*}" >&2
	"$@" || die "adhd-bazel failed"
}

use_label() {
	usex "$1" --"$2" --no"$2"
}

src_unpack() {
	bazel_load_distfiles "${bazel_external_uris}"
	cros-workon_src_unpack
}

src_prepare() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)
  eapply $FILESDIR/*.patch
	sanitizers-setup-env
	default
}

src_configure() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)

	cros_optimize_package_for_speed
	if use amd64 ; then
		export FUZZER_LDFLAGS="-fsanitize=fuzzer"
	fi

	common_bazel_args=(
		# For libcras.pc generation only.
		# cros-bazel.eclass gives /build/<board>/usr, which is not what we want.
		# Restore the bazel.eclass behavior.
		"--define=PREFIX=${EPREFIX%/}/usr"

		"--config=clang-strict"
		"--override_repository=rules_rust=${S}/cras/rules_rust_stub"
		"--define=VCSID=${VCSID}"
		"--//:hw_dependency"
		"--//:system_cras_rust"
		"--//:hats"
		"--//:metrics"
		"$(use_label cras-apm //:apm)"
		"$(use_label cras-ml //:ml)"
		"$(use_label dlc //:dlc)"
		"$(use_label featured //:featured)"
	)
	if use fuzzer; then
		common_bazel_args+=(
			"--config=fuzzer"
			# Selinux does not work with fuzzers.
			"--no//:selinux"
		)
	else
		common_bazel_args+=(
			"$(use_label selinux //:selinux)"
		)
	fi
	if use ubsan; then
		common_bazel_args+=(
			# Bazel links using C mode by default, which misses symbols.
			# https://github.com/bazelbuild/bazel/issues/11122#issuecomment-896613570
			"--linkopt=-fsanitize-link-c++-runtime"
		)
	fi
	if [[ "${PV}" != "9999" ]]; then
		common_bazel_args+=(
			# Disable fancy output when not being "workon" to not spam CQ logs.
			"--color=no"
			"--curses=no"
		)
	fi
	if use cras-debug; then
		common_bazel_args+=(
			"--compilation_mode=dbg"
		)
	fi
}

src_compile() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)

	# Prevent clang to access ubsan_blocklist.txt which is not supported by bazel.
	filter-flags -fsanitize-blacklist="${S}"/ubsan_blocklist.txt
	bazel_setup_crosstool

	# Build and copy artifacts.
	rm -rf "${T}/dist"
	adhd-bazel run "${common_bazel_args[@]}" //dist -- "${T}/dist"
}

src_test() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)

	if ! use x86 && ! use amd64 ; then
		elog "Skipping unit tests on non-x86 platform"
		return
	fi
	if use fuzzer ; then
		elog "Skipping unit tests on fuzzer build"
		return
	fi

	args=(
		"--test_output=errors"
		"--keep_going"

		# This is an ugly hack that happens to work, but should not be copied.
		"--test_env=LD_LIBRARY_PATH=${SYSROOT}/$(get_libdir):${SYSROOT}/usr/$(get_libdir)"

		# Pass sanitizer environment variables to the test executable.
		# Also override log_path so errors are shown immediately after
		# the test failure, instead of displayed by asan_death_hook
		# at the bottom of emerge's output:
		# https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/third_party/chromiumos-overlay/profiles/base/profile.bashrc;l=494;drc=14244882a39e40a61fdcdfeec156592bb00f3905
		"--test_env=ASAN_OPTIONS=${ASAN_OPTIONS} log_path=stderr"
		"--test_env=MSAN_OPTIONS=${MSAN_OPTIONS} log_path=stderr"
		"--test_env=TSAN_OPTIONS=${TSAN_OPTIONS} log_path=stderr"
		"--test_env=UBSAN_OPTIONS=${UBSAN_OPTIONS} log_path=stderr"
		"--test_env=LSAN_OPTIONS"

		"--"
		"//..."
	)
	adhd-bazel test "${common_bazel_args[@]}" "${args[@]}"
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

	if ! use fuzzer ; then
		dobin "${T}/dist/bin/"*
		doheader "${T}/dist/include"/*
		dolib.so "${T}/dist/lib"/*.so

		dosym libcras.so "/usr/$(get_libdir)/libcras.so.0"
		dosym libcras.so "/usr/$(get_libdir)/libcras.so.0.0.0"

		insinto "/usr/$(get_libdir)"
		doins -r "${T}/dist/alsa-lib"

		insinto "/usr/$(get_libdir)/pkgconfig"
		doins "${T}/dist/pkgconfig"/*

		# Install cras_bench into /usr/local for test image
		into /usr/local
		dobin "${T}/dist/extra_bin/"*
	else
		# Install example dsp.ini file for fuzzer
		insinto /etc/cras
		doins cras-config/dsp.ini.sample
		# Install fuzzer binary
		local fuzzer_component_id="890231"
		fuzzer_install "${S}/OWNERS.fuzz" "${T}/dist/fuzzer"/cras_rclient_message_fuzzer \
			--comp "${fuzzer_component_id}"
		fuzzer_install "${S}/OWNERS.fuzz" "${T}/dist/fuzzer"/cras_hfp_slc_fuzzer \
			--dict "${S}/cras/src/fuzz/cras_hfp_slc.dict" \
			--comp "${fuzzer_component_id}"
		local fuzzer_component_id="769744"
		fuzzer_install "${S}/OWNERS.fuzz" "${T}/dist/fuzzer"/cras_fl_media_fuzzer \
			--comp "${fuzzer_component_id}"
	fi
}

pkg_preinst() {
	enewuser "cras"
	enewgroup "cras"
	enewgroup "bluetooth-audio"
}
