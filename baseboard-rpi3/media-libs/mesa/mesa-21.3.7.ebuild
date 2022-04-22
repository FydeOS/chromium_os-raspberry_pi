# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7
MESON_AUTO_DEPEND=no

CROS_WORKON_COMMIT="d5ec846bc8cbf9bdb99daeec001bc95a4e6d6318"
CROS_WORKON_TREE="1972ec61637a2ec1152ac8d8fdb91c8df68f2df2"

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
#CROS_WORKON_MANUAL_UPREV="1"
CROS_WORKON_EGIT_BRANCH="master"

inherit base meson flag-o-matic cros-workon

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"
KEYWORDS="*"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"

IUSE="debug vulkan egl gles2 libglvnd"

COMMON_DEPEND="
	dev-libs/expat:=
	>=x11-libs/libdrm-2.4.94:=
"

RDEPEND="${COMMON_DEPEND}
  libglvnd? ( media-libs/libglvnd )
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
    -Dglvnd=$(usex libglvnd true false)
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

#PATCHES=(
#  "${FILESDIR}/0001-limit-gles-version.patch"
#  "${FILESDIR}/fix-v3d-screen-disorder-issue-mesa-21.patch"
#)
