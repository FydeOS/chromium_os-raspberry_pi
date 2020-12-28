# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="cbe5934fd21d579a7bcffa6c7ae2567d361a6705"
CROS_WORKON_TREE="bfd09ab3e5c477cdb942fd0291460e01d1d37182"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa-iris"
CROS_WORKON_EGIT_BRANCH="chromeos-iris"

KEYWORDS="*"

inherit base meson flag-o-matic cros-workon

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"

IUSE="debug vulkan tools"

COMMON_DEPEND="
	dev-libs/expat:=
	>=x11-libs/libdrm-2.4.94:=
"

RDEPEND="${COMMON_DEPEND}
"

DEPEND="${COMMON_DEPEND}
"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
"

src_configure() {
	emesonargs+=(
		-Dllvm=false
		-Ddri3=false
		-Dshader-cache=false
		-Dglx=disabled
		-Degl=true
		-Dgbm=false
		-Dgles1=false
		-Dgles2=true
		-Dshared-glapi=true
		-Ddri-drivers=
		-Dgallium-drivers="vc4,v3d"
		-Dgallium-vdpau=false
		-Dgallium-xa=false
		-Dplatforms=surfaceless
		-Dtools=
		--buildtype $(usex debug debug release)
 		-Dvulkan-drivers=
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	rm -v -rf "${ED}/usr/include"
}
