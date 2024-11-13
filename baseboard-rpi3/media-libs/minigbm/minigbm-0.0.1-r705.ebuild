# Copyright 2014 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

CROS_WORKON_COMMIT="c52bbc8435516643f696c602d1442719a232f7e6"
CROS_WORKON_TREE="2ff4b83e46449a4cc032a6f89976f725843afb70"
CROS_WORKON_PROJECT="chromiumos/platform/minigbm"
CROS_WORKON_LOCALNAME="../platform/minigbm"
CROS_WORKON_OUTOFTREE_BUILD=1

inherit cros-sanitizers cros-workon cros-common.mk multilib

DESCRIPTION="Mini GBM implementation"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/minigbm"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
VIDEO_CARDS="
	amdgpu exynos intel marvell mediatek msm
	radeon radeonsi rockchip tegra vc4 virgl v3d
"
IUSE="-asan linear_align_256 test"
for card in ${VIDEO_CARDS}; do
	IUSE+=" video_cards_${card}"
done

MINI_GBM_PLATFORMS_USE=( mt8173 mt8183 mt8186 mt8188g mt8192 mt8195 sc7280)
IUSE+=" ${MINI_GBM_PLATFORMS_USE[*]/#/minigbm_platform_}"

IUSE+=" intel_drm_tile4"

RDEPEND="
	x11-libs/libdrm
	test? ( dev-cpp/gtest )
	!media-libs/mesa[gbm]"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	video_cards_amdgpu? (
		virtual/opengles
		x11-drivers/opengles-headers
	)"

src_prepare() {
  eapply ${FILESDIR}/vc6.patch
	default
	sanitizers-setup-env
	cros-common.mk_src_prepare
}

src_configure() {
	export LIBDIR="/usr/$(get_libdir)"
	append-cppflags -DDRI_DRIVER_DIR="/usr/$(get_libdir)/dri"
	use video_cards_amdgpu && append-cppflags -DDRV_AMDGPU && export DRV_AMDGPU=1
	use video_cards_exynos && append-cppflags -DDRV_EXYNOS && export DRV_EXYNOS=1
	use video_cards_intel && append-cppflags -DDRV_I915 && export DRV_I915=1
	if use video_cards_intel ; then
		if use intel_drm_tile4 ; then
			append-cppflags -DI915_SCANOUT_4_TILED
		else
			append-cppflags -DI915_SCANOUT_Y_TILED
		fi
	fi
	use video_cards_marvell && append-cppflags -DDRV_MARVELL && export DRV_MARVELL=1
	use minigbm_platform_mt8173 && append-cppflags -DMTK_MT8173
	use minigbm_platform_mt8183 && append-cppflags -DMTK_MT8183
	use minigbm_platform_mt8186 && append-cppflags -DMTK_MT8186
	use minigbm_platform_mt8188g && append-cppflags -DMTK_MT8188G
	use minigbm_platform_mt8192 && append-cppflags -DMTK_MT8192
	use minigbm_platform_mt8195 && append-cppflags -DMTK_MT8195
	use minigbm_platform_sc7280 && append-cppflags -DSC_7280
	use video_cards_mediatek && append-cppflags -DDRV_MEDIATEK -DDRV_PANFROST && export DRV_MEDIATEK=1
	use video_cards_msm && append-cppflags -DDRV_MSM && export DRV_MSM=1
	use video_cards_radeon && append-cppflags -DDRV_RADEON && export DRV_RADEON=1
	use video_cards_radeonsi && append-cppflags -DDRV_RADEON && export DRV_RADEON=1
	use video_cards_rockchip && append-cppflags -DDRV_ROCKCHIP && export DRV_ROCKCHIP=1
	use video_cards_tegra && append-cppflags -DDRV_TEGRA && export DRV_TEGRA=1
	use video_cards_vc4 && append-cppflags -DDRV_VC4 && export DRV_VC4=1
	use video_cards_virgl && append-cppflags -DDRV_VIRGL && export DRV_VIRGL=1
	use linear_align_256 && append-cppflags -DLINEAR_ALIGN_256
  use video_cards_v3d && append-cppflags -DDRV_V3D && export DRV_V3D=1
	cros-common.mk_src_configure
}

src_test() {
	if use amd64 || use x86; then
		emake tests
	fi
}

src_compile() {
	cros-common.mk_src_compile
}

src_install() {
	insinto "${EPREFIX}/etc/udev/rules.d"
	doins "${FILESDIR}/50-vgem.rules"

	default
}
