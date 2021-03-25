# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="0f4f2e09dc2ab3255685c3005d3f60081f3a2a09"
CROS_WORKON_TREE=("52a8a8b6d3bbca5e90d4761aa308a5541d52b1bb" "04eb33e4a1a28c4e52176cad04e7d44c0fc80b33" "2b6d4230c92e83e39209823855064483eed04754" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk installer verity .gn"

PLATFORM_SUBDIR="installer"

inherit cros-workon platform systemd

DESCRIPTION="Chrome OS Installer"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/installer/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="cros_embedded enable_slow_boot_notify -mtd pam systemd +oobe_config lvm_stateful_partition"

COMMON_DEPEND="
	chromeos-base/libbrillo:=
	chromeos-base/vboot_reference
	x11-libs/libxkbcommon:=
	x11-misc/xkeyboard-config:=
"

DEPEND="${COMMON_DEPEND}
	chromeos-base/verity
	dev-libs/openssl:0=
"

RDEPEND="${COMMON_DEPEND}
	pam? ( app-admin/sudo )
	chromeos-base/chromeos-common-script
	!cros_embedded? ( chromeos-base/chromeos-storage-info )
	oobe_config? ( chromeos-base/oobe_config )
	dev-libs/openssl:0=
	dev-util/shflags
	sys-apps/rootdev
	sys-apps/util-linux
	sys-apps/which
	sys-fs/e2fsprogs"

platform_pkg_test() {
	platform_test "run" "${OUT}/cros_installer_test"
}

src_install() {
	dobin "${OUT}"/{cros_installer,cros_oobe_crypto}
	if use mtd ; then
		dobin "${OUT}"/nand_partition
	fi
	dosbin chromeos-* encrypted_import "${OUT}"/{evwaitkey,key_reader}
	dosym usr/sbin/chromeos-postinst /postinst

	# Enable lvm stateful partition.
	if use lvm_stateful_partition; then
		sed -i '/DEFINE_boolean lvm_stateful "/s:\${FLAGS_FALSE}:\${FLAGS_TRUE}:' \
			"${D}/usr/sbin/chromeos-install" ||
			die "Failed to set 'lvm_stateful' in chromeos-install"
	fi

	# Install init scripts.
	if use systemd; then
		systemd_dounit init/install-completed.service
		systemd_enable_service boot-services.target install-completed.service
		systemd_dounit init/crx-import.service
		systemd_enable_service system-services.target crx-import.service
	else
		insinto /etc/init
		doins init/*.conf
	fi
	exeinto /usr/share/cros/init
	doexe init/crx-import.sh
  exeinto /usr/sbin
  doexe ${FILESDIR}/switch_root.sh
  doexe ${FILESDIR}/update_kernel.sh
  insinto /usr/share/cros
  doins ${FILESDIR}/update_kernel_lib.sh
}

src_prepare() {
  epatch ${FILESDIR}/chromeos-install.patch
  epatch ${FILESDIR}/postinst.patch
  default
}
