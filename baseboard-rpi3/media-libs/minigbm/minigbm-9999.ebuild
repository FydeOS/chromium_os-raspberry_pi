# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

CROS_WORKON_PROJECT="chromiumos/platform/minigbm"
CROS_WORKON_LOCALNAME="../platform/minigbm"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1

inherit cros-sanitizers cros-workon cros-common.mk toolchain-funcs multilib

DESCRIPTION="Mini GBM implementation"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/minigbm"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
VIDEO_CARDS="
	amdgpu exynos intel marvell mediatek msm
	radeon radeonsi rockchip tegra vc4 virgl
"
IUSE="-asan"
for card in ${VIDEO_CARDS}; do
	IUSE+=" video_cards_${card}"
done

RDEPEND="
	x11-libs/libdrm
	!media-libs/mesa[gbm]"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	video_cards_amdgpu? ( media-libs/mesa )"

src_prepare() {
	default
	sanitizers-setup-env
	cros-common.mk_src_prepare
}

src_configure() {
	export LIBDIR="/usr/$(get_libdir)"
	use video_cards_amdgpu && append-cppflags -DDRV_AMDGPU && export DRV_AMDGPU=1
	use video_cards_exynos && append-cppflags -DDRV_EXYNOS && export DRV_EXYNOS=1
	use video_cards_intel && append-cppflags -DDRV_I915 && export DRV_I915=1
	use video_cards_marvell && append-cppflags -DDRV_MARVELL && export DRV_MARVELL=1
	use video_cards_mediatek && append-cppflags -DDRV_MEDIATEK && export DRV_MEDIATEK=1
	use video_cards_msm && append-cppflags -DDRV_MSM && export DRV_MSM=1
	use video_cards_radeon && append-cppflags -DDRV_RADEON && export DRV_RADEON=1
	use video_cards_radeonsi && append-cppflags -DDRV_RADEON && export DRV_RADEON=1
	use video_cards_rockchip && append-cppflags -DDRV_ROCKCHIP && export DRV_ROCKCHIP=1
	use video_cards_tegra && append-cppflags -DDRV_TEGRA && export DRV_TEGRA=1
	use video_cards_vc4 && append-cppflags -DDRV_VC4 && export DRV_VC4=1
	use video_cards_virgl && append-cppflags -DDRV_VIRGL && export DRV_VIRGL=1
	cros-common.mk_src_configure
}

src_compile() {
	cros-common.mk_src_compile
}

src_install() {
	insinto "${EPREFIX}/etc/udev/rules.d"
	doins "${FILESDIR}/50-vgem.rules"

	default
}
