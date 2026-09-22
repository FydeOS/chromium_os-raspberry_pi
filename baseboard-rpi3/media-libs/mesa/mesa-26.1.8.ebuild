# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Mesa 26.1.8, pinned to the same upstream release commit as
# chipset-rk3588's media-libs/mesa-panthor (both share the
# chromiumos/third_party/mesa checkout at src/third_party/mesa).
CROS_WORKON_COMMIT="0fadfea4f394211946f308458f614839ef253ee8"
CROS_WORKON_TREE="37cab8cb62626d8c33d536e6a74ba7cf9bea602d"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa"
CROS_WORKON_MANUAL_UPREV="1"
CROS_WORKON_EGIT_BRANCH="cros/upstream/26.1"

KEYWORDS="*"

inherit meson flag-o-matic cros-workon

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"

IUSE="debug vulkan libglvnd zstd egl gles2 perfetto"

COMMON_DEPEND="
	dev-libs/expat:=
	>=x11-libs/libdrm-2.4.94:=
"

RDEPEND="${COMMON_DEPEND}
	libglvnd? ( media-libs/libglvnd )
	!libglvnd? ( !media-libs/libglvnd )
	zstd? ( app-arch/zstd )
  dev-libs/libxml2
  app-arch/libarchive:=
  dev-libs/libconfig:=
  sys-libs/ncurses:=
  >=sys-libs/zlib-1.2.13
  virtual/libudev:=
  dev-util/spirv-tools
"

DEPEND="${COMMON_DEPEND}
	perfetto? ( >=chromeos-base/perfetto-29.0 )
"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
"

src_configure() {
	cros_optimize_package_for_speed
	emesonargs+=(
		-Dglvnd=$(usex libglvnd enabled disabled)
		-Dllvm=disabled
		-Dshader-cache=enabled
		-Dshader-cache-default=false
		# Keep libgallium's DSO name stable across Mesa bumps, as
		# media-libs/mesa-panthor does; libEGL/libGLESv2 link it directly.
		-Dunversion-libgallium=true
		-Dglx=disabled
		-Degl=enabled
		-Dgbm=disabled
		-Dgles1=disabled
		-Dgles2=enabled
		-Dgallium-drivers=v3d,vc4
		-Dperfetto=$(usex perfetto true false)
		$(meson_feature zstd)
		# Surfaceless ChromeOS build: no libdisplay-info.
		-Ddisplay-info=disabled
		-Degl-native-platform="surfaceless"
		-Dplatforms=
		-Dtools=
		--buildtype $(usex debug debug release)
		-Dvulkan-drivers=$(usex vulkan broadcom '')
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	rm -v -rf "${ED}/usr/include"
}

# 001 (v3d disk-cache guard) is upstream in 26.1; 004 (android log dep) is dead
# with -Dplatforms= empty; 005 (dril for chromiumos) is dropped - nothing on the
# Pi dlopens dri/*_dri.so, Chrome's libEGL links libgallium directly.
PATCHES=(
  "${FILESDIR}/002-fix-v3d-screen-disorder-issue.patch"
  "${FILESDIR}/003-fix-vulkan-chromeos.patch"
)
