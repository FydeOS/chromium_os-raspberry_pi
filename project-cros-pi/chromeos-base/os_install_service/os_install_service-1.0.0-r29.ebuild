# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2021 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="40e1bc26badfabd2aa35666b44da5642e05b2fb4"
CROS_WORKON_TREE="f1e762792290e259d1c6e45a9a0e2593e12043a5"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="os_install_service"

inherit cros-workon cros-rust tmpfiles

RESTRICT="arm? ( binchecks )"

LICENSE="BSD-Google"
SLOT="0/${PVR}"
KEYWORDS="*"
IUSE="test"

DEPEND="
	dev-rust/third-party-crates-src:=
	chromeos-base/system_api:=
	=dev-rust/anyhow-1.0*
	=dev-rust/chrono-0.4*
	=dev-rust/crossbeam-channel-0.5*
	=dev-rust/dbus-0.8*
	dev-rust/libchromeos:=
	=dev-rust/log-0.4*
	=dev-rust/nix-0.23*
	=dev-rust/serde_json-1.0*
	dev-rust/sys_util:=
	=dev-rust/tempfile-3*
"

RDEPEND="
	chromeos-base/chromeos-installer
	sys-apps/util-linux
	sys-block/parted
"

src_prepare() {
	cros-rust_src_prepare
	eapply -p2 "${FILESDIR}/0001-add-args-for-chromeos-install-to-make-it-work-on-pi.patch"
	eapply -p2 "${FILESDIR}/0002-remove-os_install_service-seccomp-policy-for-minijail.patch"
	eapply_user
}

src_install() {
	insinto /etc/dbus-1/system.d
	doins conf/org.chromium.OsInstallService.conf

	# insinto /usr/share/policy
	# newins "conf/os_install_service-seccomp-${ARCH}.policy" os_install_service-seccomp.policy

	insinto /etc/init
	doins conf/os_install_service.conf

	newtmpfiles conf/tmpfiles.conf os_install_service.conf

	dosbin "$(cros-rust_get_build_dir)/is_running_from_installer"
	dosbin "$(cros-rust_get_build_dir)/os_install_service"
}
