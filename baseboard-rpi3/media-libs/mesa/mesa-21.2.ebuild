# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7
MESON_AUTO_DEPEND=no

CROS_WORKON_COMMIT="e2889fb2d14e5d440941bdc76b6588359d579323"
CROS_WORKON_TREE="1972ec61637a2ec1152ac8d8fdb91c8df68f2df2"

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_MANUAL_UPREV="1"
CROS_WORKON_EGIT_BRANCH="master"

inherit base meson flag-o-matic cros-workon

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"

IUSE="debug vulkan egl gles2"

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
		-Dllvm=disabled
		-Ddri3=disabled
		-Dshader-cache=disabled
		-Dglx=disabled
		-Degl=enabled
		-Dgbm=disabled
		-Dgles1=enabled
		-Dgles2=enabled
		-Dshared-glapi=enabled
		-Ddri-drivers=
		-Dgallium-drivers=vc4,v3d
		-Dgallium-vdpau=disabled
		-Dgallium-xa=disabled
		-Dplatforms=
		-Dtools=
		--buildtype $(usex debug debug release)
		-Dvulkan-drivers=$(usex vulkan broadcom '')
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	find "${ED}" -name '*kgsl*' -exec rm -f {} +
  find "${ED}"/usr/lib/dri -not -name 'v*' -exec rm -f {} +
	rm -v -rf "${ED}/usr/include"
}
