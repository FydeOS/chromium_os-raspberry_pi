# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="4f4f8680ffb75e1d9135e4b8678a9d9a3a1985b6"
CROS_WORKON_TREE="a2de5deab76033ac1ea413e4494113ef249fa663"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="os_install_service"

inherit cros-workon cros-rust tmpfiles

LICENSE="BSD-Google"
SLOT="0/${PVR}"
KEYWORDS="*"
IUSE="test"

DEPEND="
	chromeos-base/system_api:=
	=dev-rust/anyhow-1.0*:=
	=dev-rust/chrono-0.4*:=
	=dev-rust/crossbeam-channel-0.5*:=
	=dev-rust/dbus-0.8*:=
	=dev-rust/lazy_static-1.4*:=
	=dev-rust/log-0.4*:=
	=dev-rust/nix-0.19*:=
	=dev-rust/serde-1.0*:=
	=dev-rust/serde_json-1.0*:=
	dev-rust/sys_util:=
	=dev-rust/tempfile-3*:=
	=dev-rust/thiserror-1.0*:=
"

RDEPEND="
	chromeos-base/chromeos-installer
	sys-apps/util-linux
	sys-block/parted
"

src_install() {
	# insinto /etc/dbus-1/system.d
	# doins conf/org.chromium.OsInstallService.conf
	#
	# insinto /usr/share/policy
	# newins "conf/os_install_service-seccomp-${ARCH}.policy" os_install_service-seccomp.policy
	#
	# insinto /etc/init
	# doins conf/os_install_service.conf
	#
	# newtmpfiles conf/tmpfiles.conf os_install_service.conf

	dosbin "$(cros-rust_get_build_dir)/is_running_from_installer"
	# dosbin "$(cros-rust_get_build_dir)/os_install_service"
}
