# Copyright 2012 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

PYTHON_COMPAT=( python3_{8..11} )

CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_PROJECT=(
	"chromiumos/third_party/adhd"
	"chromiumos/third_party/webrtc-apm"
	"chromiumos/platform2"
)
CROS_WORKON_LOCALNAME=(
	"adhd"
	"webrtc-apm"
	"../platform2"
)
CROS_WORKON_SUBTREE=(
	""
	""
	"common-mk"
)
CROS_WORKON_DESTDIR=(
	"${S}/adhd"
	"${S}/webrtc-apm"
	"${S}/platform2"
)
CROS_WORKON_USE_VCSID=1

inherit python-any-r1 toolchain-funcs cros-bazel cros-fuzzer cros-sanitizers cros-workon
inherit cros-unibuild cros-debug systemd user

DESCRIPTION="Google A/V Daemon"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/adhd/"

# The URIs are separated into two parts.
# 1. Explicit dependencies listed in WORKSPACE.bazel.
#    These can be generated with:
#    bazel build //repositories/http_archive_deps:bazel_external_uris
# 2. Implicit dependencies of Bazel. Manitained manually.
bazel_external_uris="
	https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz -> bazelbuild-bazel-skylib-1.4.1.tar.gz
	https://github.com/bazelbuild/rules_cc/releases/download/0.0.6/rules_cc-0.0.6.tar.gz -> bazelbuild-rules_cc-0.0.6.tar.gz
	https://github.com/bazelbuild/rules_license/releases/download/0.0.4/rules_license-0.0.4.tar.gz -> bazelbuild-rules_license-0.0.4.tar.gz
	https://github.com/bazelbuild/rules_pkg/releases/download/0.9.1/rules_pkg-0.9.1.tar.gz -> bazelbuild-rules_pkg-0.9.1.tar.gz
	https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz -> bazelbuild-rules_python-0.1.0.tar.gz
	https://github.com/bazelbuild/rules_rust/releases/download/0.24.0/rules_rust-v0.24.0.tar.gz -> bazelbuild-rules_rust-v0.24.0.tar.gz
	https://github.com/google/benchmark/archive/refs/tags/v1.7.1.tar.gz -> google-benchmark-v1.7.1.tar.gz
	https://github.com/hedronvision/bazel-compile-commands-extractor/archive/0197fc673a1a6035078ac7790318659d7442e27e.tar.gz -> hedronvision-bazel-compile-commands-extractor-0197fc673a1a6035078ac7790318659d7442e27e.tar.gz
	https://github.com/ndevilla/iniparser/archive/refs/tags/v4.1.tar.gz -> ndevilla-iniparser-v4.1.tar.gz
	https://github.com/thesofproject/sof/archive/refs/tags/v2.5.tar.gz -> thesofproject-sof-v2.5.tar.gz
	https://storage.googleapis.com/chromiumos-test-assets-public/tast/cros/audio/the-quick-brown-fox_20230131.wav

	https://github.com/bazelbuild/rules_java/archive/7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip -> bazelbuild-rules_java-7cf3cefd652008d0a64a419c34c13bdca6c8f178.zip
	https://mirror.bazel.build/bazel_coverage_output_generator/releases/coverage_output_generator-v2.5.zip
	https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz -> bazelbuild-rules_proto-7e4afce6fe62dbff0a4a03450143146f9f2d7488.tar.gz
	https://mirror.bazel.build/openjdk/azul-zulu11.50.19-ca-jdk11.0.12/zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz -> bazel-zulu11.50.19-ca-jdk11.0.12-linux_x64.tar.gz
	https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools-v11.7.1.zip
	https://mirror.bazel.build/bazel_java_tools/releases/java/v11.6/java_tools_linux-v11.7.1.zip
"
SRC_URI="${bazel_external_uris}"
LICENSE="Apache-2.0 BSD-Google MIT"
KEYWORDS="~*"
IUSE="asan +cras-apm cras-debug cras-ml cros-debug dlc featured fuzzer neon selinux systemd test"

COMMON_DEPEND="
	chromeos-base/chromeos-config-tools:=
	chromeos-base/featured:=
	chromeos-base/libsegmentation:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	dev-cpp/abseil-cpp:=
	dev-libs/libevent:=
	dev-libs/openssl:0=
	dev-libs/protobuf:=
	>=media-libs/alsa-lib-1.1.6-r3:=
	media-libs/ladspa-sdk:=
	media-libs/sbc:=
	media-libs/speex:=
	>=media-sound/cras_rust-0.1.1:=
	cras-ml? ( sci-libs/tensorflow:= )
	>=sys-apps/dbus-1.4.12:=
	selinux? ( sys-libs/libselinux:= )
	virtual/libudev:=
	test? (
		app-shells/dash
		sys-apps/diffutils
		sys-apps/grep
		sys-apps/which
	)
"

RDEPEND="
	${COMMON_DEPEND}
	media-sound/alsa-utils
	dlc? ( media-sound/sr-bt-dlc:= )
	dlc? ( virtual/chromeos-audio-nc-ap-dlc:= )
	media-plugins/alsa-plugins
	!<media-sound/cras_rust-0.1.1
	!media-libs/webrtc-apm
	virtual/udev
"

DEPEND="
	${COMMON_DEPEND}
	dev-libs/libpthread-stubs:=
	test? (
		dev-lang/python
		sys-apps/coreutils
	)
"

BDEPEND="
	chromeos-base/minijail
	dev-libs/protobuf
	sys-apps/which
	sys-devel/gettext
	${PYTHON_DEPS}
"

adhd-get_build_dir() {
	if use coverage; then
		# We don't want incremental builds for coverage:
		# 1. Tests are not re-run between invocations of incremental builds.
		# 2. profile.bashrc does not know to look into cros-workon_get_build_dir.
		# So follow the behavior of non-incremental builds of
		# cros-workon_get_build_dir.
		echo "${WORKDIR}/build"
	else
		cros-workon_get_build_dir
	fi
}

adhd-bazel() {
	bazel_setup_bazelrc
	set -- bazel --bazelrc="${T}/bazelrc" --output_user_root="$(adhd-get_build_dir)" "$@"
	echo "${*}" >&2
	"$@" || die "adhd-bazel failed"
}

use_label() {
	usex "$1" --"$2" --no"$2"
}

src_unpack() {
	bazel_load_distfiles "${bazel_external_uris}"
	cros-workon_src_unpack

	# Fix up for license scanning.
	# Remove license template file.
	rm "${S}/adhd/LICENSE.tpl" || die
	# devtools/ are not used to build this package.
	rm -r "${S}/adhd/devtools" || die
}

src_prepare() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)
	sanitizers-setup-env
	default
}

src_configure() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)

	python_setup

	cros_optimize_package_for_speed
	cros-debug-add-NDEBUG

	if use amd64 ; then
		export FUZZER_LDFLAGS="-fsanitize=fuzzer"
	fi

	common_bazel_args=(
		# For libcras.pc generation only.
		# cros-bazel.eclass gives /build/<board>/usr, which is not what we want.
		# Restore the bazel.eclass behavior.
		"--define=PREFIX=${EPREFIX%/}/usr"

		"--config=clang-strict"
		"--override_repository=rules_rust=${S}/adhd/cras/rules_rust_stub"
		"--override_repository=com_google_absl=${S}/adhd/third_party/system_absl"
		"--define=VCSID=${VCSID}"
		"--//:chromeos"
		"--//:featured"
		"--//:hats"
		"--//:hw_dependency"
		"--//:metrics"
		"--//:system_cras_rust"
		"--//dist:libdir=$(get_libdir)"
		"$(use_label cras-apm //:apm)"
		"$(use_label cras-ml //:ml)"
		"$(use_label dlc //:dlc)"
	)
	if use cras-apm; then
		common_bazel_args+=(
			"--@webrtc_apm//:chromiumos"
		)
		common_bazel_args+=(
			"$(use_label neon @webrtc_apm//:neon)"
		)
	fi
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
	if use coverage; then
		common_bazel_args+=(
			# Embed the absolute path for coverage.
			"--copt=-fcoverage-compilation-dir=${S}/adhd"
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
	rm -f "${T}/dist.tar"
	rm -rf "${T}/fuzzers"
	cd "${S}/adhd" || die
	if ! use fuzzer ; then
		adhd-bazel build "${common_bazel_args[@]}" //dist:default
		cp bazel-bin/dist/default.tar "${T}/dist.tar" || die
	else
		adhd-bazel build "${common_bazel_args[@]}" //dist:fuzzers
		mkdir "${T}/fuzzers" || die
		tar -C "${T}/fuzzers" -xf bazel-bin/dist/fuzzers.tar || die
	fi

	# Add license for vendored code for license scanning.
	mkdir -p "external/iniparser" || die
	cp "bazel-out/../../../external/iniparser/LICENSE" \
		"external/iniparser/LICENSE" || die

	# Add license for thesofproject/sof source code for license scanning.
	# Note: it's named LICEN'C'E in thesofproject_sof whilst LICEN'S'E in iniparser.
	mkdir -p "external/thesofproject_sof" || die
	cp "bazel-out/../../../external/thesofproject_sof/LICENCE" \
		"external/thesofproject_sof/LICENCE" || die
}

src_test() {
	export JAVA_HOME=$(ROOT="${BROOT}" java-config --jdk-home)

	if use fuzzer ; then
		elog "Skipping unit tests on fuzzer build"
		return
	fi

	local platform2_test_py="${S}/platform2/common-mk/platform2_test.py"

	args=(
		"--test_output=errors"
		"--keep_going"

		"--run_under=${FILESDIR}/symbolize_run.sh ${platform2_test_py} --sysroot=${SYSROOT} --strategy=unprivileged --user=root --"

		# Running tests is cheap compared to the build time, don't cache test results.
		"--cache_test_results=no"

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
		"--test_env=SYSROOT=${SYSROOT}"

		# profile.bashrc sets LLVM_PROFILE_FILE to tell the path to write *.profraw files.
		"--test_env=LLVM_PROFILE_FILE"

		"--"
		"//..."
	)
	if use cras-apm; then
		args+=(
			"@webrtc_apm//:tests"
		)
	fi
	cd "${S}/adhd" || die
	adhd-bazel test "${common_bazel_args[@]}" "${args[@]}"
}

src_install() {
	cd "${S}/adhd" || die

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
		einfo Installing dist.tar
		tar -C "${D}" -xvvf "${T}/dist.tar" || die
	else
		# Install example dsp.ini file for fuzzer
		insinto /etc/cras
		doins cras-config/dsp.ini.sample
		# Install fuzzer binary
		local fuzzer_component_id="890231"
		fuzzer_install "${S}/adhd/OWNERS.fuzz" "${T}/fuzzers"/cras_rclient_message_fuzzer \
			--comp "${fuzzer_component_id}"
		fuzzer_install "${S}/adhd/OWNERS.fuzz" "${T}/fuzzers"/cras_hfp_slc_fuzzer \
			--dict "${S}/adhd/cras/src/fuzz/cras_hfp_slc.dict" \
			--comp "${fuzzer_component_id}"
		local fuzzer_component_id="769744"
		fuzzer_install "${S}/adhd/OWNERS.fuzz" "${T}/fuzzers"/cras_fl_media_fuzzer \
			--comp "${fuzzer_component_id}"
	fi
}

pkg_preinst() {
	enewuser "cras"
	enewgroup "cras"
	enewgroup "bluetooth-audio"
}
