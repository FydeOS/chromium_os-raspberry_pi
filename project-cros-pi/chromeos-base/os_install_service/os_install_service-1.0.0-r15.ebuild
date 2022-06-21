# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="294870a7f201b6c642f6c71f8f76446f03342fca"
CROS_WORKON_TREE="738cdff72faf980c44df8e7ceb067cc951dfe990"
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
