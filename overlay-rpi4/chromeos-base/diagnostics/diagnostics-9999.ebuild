# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_PROJECT="chromiumos/platform2"
# TODO(crbug.com/1044813): Remove chromeos-config once its public headers are fixed.
CROS_WORKON_SUBTREE="common-mk chromeos-config diagnostics .gn"

PLATFORM_SUBDIR="diagnostics"

inherit cros-workon platform udev user

DESCRIPTION="Device telemetry and diagnostics for Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/diagnostics"

LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE="fuzzer wilco generated_cros_config unibuild"

COMMON_DEPEND="
	unibuild? (
		!generated_cros_config? ( chromeos-base/chromeos-config:= )
		generated_cros_config? ( chromeos-base/chromeos-config-bsp:= )
	)
	chromeos-base/chromeos-config-tools:=
	dev-libs/protobuf:=
	dev-libs/re2:=
	net-libs/grpc:=
	virtual/libudev:=
"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/debugd-client:=
	chromeos-base/system_api:=[fuzzer?]
	media-sound/adhd:=
"

# TODO(crbug/1085169): Replace sys-block/fio dependency with an alternative as
# it is very large. It is currently only a dependency of wilco as it is
# currently the only client.
RDEPEND="
	${COMMON_DEPEND}
	chromeos-base/minijail
	dev-util/stressapptest
	wilco? (
		sys-block/fio
		chromeos-base/chromeos-dtc-vm
		chromeos-base/vpd
	)
"

pkg_preinst() {
	enewgroup cros_ec-access
	enewuser cros_healthd
	enewgroup cros_healthd
	enewuser healthd_ec
	enewgroup healthd_ec

	if use wilco; then
		enewuser wilco_dtc
		enewgroup wilco_dtc
	fi
}

src_install() {
	dobin "${OUT}/cros_healthd"
	dobin "${OUT}/cros-health-tool"

	if use wilco; then
		dobin "${OUT}/wilco_dtc_supportd"

		# Install seccomp policy files.
		insinto /usr/share/policy
		newins "init/wilco_dtc_supportd-seccomp-${ARCH}.policy" \
			wilco_dtc_supportd-seccomp.policy
		newins "init/wilco-dtc-e2fsck-seccomp-${ARCH}.policy" \
			wilco-dtc-e2fsck-seccomp.policy
		newins "init/wilco-dtc-resize2fs-seccomp-${ARCH}.policy" \
			wilco-dtc-resize2fs-seccomp.policy

		# Install D-Bus configuration file.
		insinto /etc/dbus-1/system.d
		doins dbus/org.chromium.WilcoDtcSupportd.conf
		doins dbus/WilcoDtcUpstart.conf

		# Install the init scripts.
		insinto /etc/init
		doins init/wilco_dtc_dispatcher.conf
		doins init/wilco_dtc_supportd.conf
		doins init/wilco_dtc.conf

		# Install udev rules.
		udev_dorules udev/99-ec_driver_files.rules
	fi

	# Install seccomp policy files.
	insinto /usr/share/policy
	newins "init/cros_healthd-seccomp-${ARCH}.policy" \
		cros_healthd-seccomp.policy
	newins "cros_healthd/seccomp/ectool_i2cread-seccomp-${ARCH}.policy" \
		ectool_i2cread-seccomp.policy
	newins "cros_healthd/seccomp/ectool_pwmgetfanrpm-seccomp-${ARCH}.policy" \
		ectool_pwmgetfanrpm-seccomp.policy
	newins "seccomp/memtester-seccomp-${ARCH}.policy" memtester-seccomp.policy

	# Install D-Bus configuration file.
	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.CrosHealthd.conf

	# Install the init scripts.
	insinto /etc/init
	doins init/cros_healthd.conf

	# Install the diagnostic routine executables.
	exeinto /usr/libexec/diagnostics
	doexe "${OUT}/floating-point-accuracy"
	doexe "${OUT}/prime-search"
	doexe "${OUT}/smartctl-check"
	doexe "${OUT}/urandom"

	# Install udev rules.
	udev_dorules udev/99-chown_dmi_dir.rules

	# Install fuzzers.
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/fetch_block_device_fuzzer
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/fetch_system_info_fuzzer
}

platform_pkg_test() {
	local tests=(
		cros_healthd_mojo_adapter_test
		cros_healthd_test
		libcommon_test
		libcros_healthd_events_test
		libcros_healthd_fetchers_test
		libcros_healthd_utils_test
		network_test
		network_diagnostics_test
		routine_test
		system_config_test
	)
	if use wilco; then
		tests+=(
			wilco_dtc_supportd_test
		)
	fi

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}
