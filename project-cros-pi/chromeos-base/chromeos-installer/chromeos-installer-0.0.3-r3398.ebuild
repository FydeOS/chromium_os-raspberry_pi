# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="f0a8fa83760bd052e3c44f3fbca7ea9282e044d7"
CROS_WORKON_TREE=("fe8d35af30ff1c2484e01cd6235a5d45c627d10d" "561b71500490e9b4bbadd49ddd494d22f4508a0d" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk installer .gn"

PLATFORM_SUBDIR="installer"

inherit cros-workon platform systemd

DESCRIPTION="Chrome OS Installer"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/installer/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="cros_embedded cros_host enable_slow_boot_notify -mtd pam systemd test +oobe_config"

COMMON_DEPEND="
	chromeos-base/libbrillo:=
	chromeos-base/vboot_reference
"

DEPEND="${COMMON_DEPEND}
	chromeos-base/verity
	dev-libs/openssl:0=
"

RDEPEND="${COMMON_DEPEND}
	pam? ( app-admin/sudo )
	chromeos-base/chromeos-common-script
	!cros_host? (
		!cros_embedded? ( chromeos-base/chromeos-storage-info )
		oobe_config? ( chromeos-base/oobe_config )
		dev-libs/openssl:0=
	)
	dev-util/shflags
	sys-apps/rootdev
	sys-apps/util-linux
	sys-apps/which
	sys-fs/e2fsprogs"

platform_pkg_test() {
	platform_test "run" "${OUT}/cros_installer_test"
}

src_install() {
	if use cros_host ; then
		dosbin chromeos-install
	else
		dobin "${OUT}"/{cros_installer,cros_oobe_crypto}
		if use mtd ; then
			dobin "${OUT}"/nand_partition
		fi
		dosbin chromeos-* encrypted_import "${OUT}"/evwaitkey
		dosym usr/sbin/chromeos-postinst /postinst

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
	fi
}

src_prepare() {
  epatch ${FILESDIR}/chromeos-install.patch
  epatch ${FILESDIR}/postinst.patch
  default
}
