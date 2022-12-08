# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2014 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="95cba42c3e39999a02c3534e6924cdd5b8cdc775"
CROS_WORKON_TREE=("79cdd007ff69259efcaad08803ef2d1498374ec4" "68018baddc5c233cc66ed952b38c268a4db7b136" "53484d9a746662594836a32e203068e89c9eae63" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk tpm2-simulator libhwsec-foundation .gn"

PLATFORM_SUBDIR="tpm2-simulator"

inherit cros-workon platform user

DESCRIPTION="TPM 2.0 Simulator"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/tpm2-simulator/"

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="*"

IUSE="+biometrics_dev selinux ti50_onboard tpm tpm2 test tpm2_simulator tpm2_simulator_manufacturer"

COMMON_DEPEND="
	tpm? ( !test? ( dev-libs/libtpms:= ) )
	tpm2? (
		chromeos-base/tpm2:=[tpm2_simulator?]
		chromeos-base/tpm2:=[tpm2_simulator_manufacturer?]
	)
	test? ( chromeos-base/tpm2:=[test] )
	chromeos-base/libhwsec-foundation:=
	chromeos-base/minijail:=
	chromeos-base/pinweaver:=
	ti50_onboard? ( !test? ( chromeos-base/ti50-emulator:= ) )
	chromeos-base/vboot_reference:=[tpm2_simulator?]
	dev-libs/openssl:0=
	sys-libs/libselinux:=
	"

RDEPEND="
	${COMMON_DEPEND}
	selinux? (
		chromeos-base/selinux-policy
	)
"
DEPEND="${COMMON_DEPEND}"

PATCHES=(
	"${FILESDIR}"/skip-selinux_restorecon.patch
	"${FILESDIR}"/tpm2-simulator-0.0.1-fix-arm-policy.patch
)

pkg_preinst() {
	enewuser tpm2-simulator
	enewgroup tpm2-simulator
}
