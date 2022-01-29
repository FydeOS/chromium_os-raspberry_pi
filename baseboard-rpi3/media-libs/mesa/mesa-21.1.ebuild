# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/mesa/mesa-7.9.ebuild,v 1.3 2010/12/05 17:19:14 arfrever Exp $

EAPI=7

MESON_AUTO_DEPEND=no

CROS_WORKON_COMMIT="997a5e622774da30930e5d35b2d2a398a14e7b0c"
CROS_WORKON_TREE="80dc2ebe7f0b4590dfd9f91955aa59cccf2bb5f8"

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_MANUAL_UPREV="1"
CROS_WORKON_EGIT_BRANCH="mesa-21.1"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit base multilib flag-o-matic meson toolchain-funcs ${GIT_ECLASS} cros-workon

FOLDER="${PV/_rc*/}"
[[ ${PV/_rc*/} == ${PV} ]] || FOLDER+="/RC"

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="http://mesa3d.sourceforge.net/"

#SRC_PATCHES="mirror://gentoo/${P}-gentoo-patches-01.tar.bz2"
if [[ $PV = 9999* ]] || [[ -n ${CROS_WORKON_COMMIT} ]]; then
	SRC_URI="${SRC_PATCHES}"
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/mesa/${FOLDER}/${P}.tar.bz2
		${SRC_PATCHES}"
fi

# Most of the code is MIT/X11.
# ralloc is LGPL-3
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT LGPL-3 SGI-B-2.0"
SLOT="0"
KEYWORDS="*"

INTEL_CARDS="intel"
RADEON_CARDS="amdgpu radeon"
VIDEO_CARDS="${INTEL_CARDS} ${RADEON_CARDS} freedreno llvmpipe mach64 mga nouveau r128 radeonsi savage sis softpipe tdfx via virgl vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	+classic debug dri drm egl +gallium -gbm gles1 gles2 kernel_FreeBSD
	kvm_guest llvm +nptl pic selinux shared-glapi vulkan wayland xlib-glx X
	libglvnd"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.60"

REQUIRED_USE="video_cards_amdgpu? ( llvm )
	video_cards_llvmpipe? ( llvm )"

# keep correct libdrm and dri2proto dep
# keep blocks in rdepend for binpkg
RDEPEND="
	libglvnd? ( media-libs/libglvnd )
	!libglvnd? ( !media-libs/libglvnd )
	X? (
		!<x11-base/xorg-server-1.7
		>=x11-libs/libX11-1.3.99.901
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXrandr
		x11-libs/libxshmfence
		x11-libs/libXxf86vm
	)
	llvm? ( virtual/libelf )
	dev-libs/expat
	dev-libs/libgcrypt
	virtual/udev
	${LIBDRM_DEPSTRING}
"

DEPEND="${RDEPEND}
	dev-libs/libxml2
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	x11-base/xorg-proto
	wayland? ( >=dev-libs/wayland-protocols-1.8 )
	llvm? ( sys-devel/llvm )
"

driver_list() {
	local drivers="$(sort -u <<< "${1// /$'\n'}")"
	echo "${drivers//$'\n'/,}"
}

src_prepare() {
	# FreeBSD 6.* doesn't have posix_memalign().
	if [[ ${CHOST} == *-freebsd6.* ]]; then
		sed -i \
			-e "s/-DHAVE_POSIX_MEMALIGN//" \
			configure.ac || die
	fi
	default
}

src_configure() {
	tc-getPROG PKG_CONFIG pkg-config

	cros_optimize_package_for_speed
	# For llvmpipe on ARM we'll get errors about being unable to resolve
	# "__aeabi_unwind_cpp_pr1" if we don't include this flag; seems wise
	# to include it for all platforms though.
	use video_cards_llvmpipe && append-flags "-rtlib=libgcc -shared-libgcc --unwindlib=libgcc"

	if use !gallium && use !classic && use !vulkan; then
		ewarn "You enabled neither classic, gallium, nor vulkan "
		ewarn "USE flags. No hardware drivers will be built."
	fi

	if use classic; then
	# Configurable DRI drivers
		# Intel code
		dri_driver_enable video_cards_intel i965
	fi

	if use gallium; then
	# Configurable gallium drivers
		gallium_enable video_cards_llvmpipe swrast
		gallium_enable video_cards_softpipe swrast

		# Nouveau code
		gallium_enable video_cards_nouveau nouveau

		# ATI code
		gallium_enable video_cards_radeon r300 r600
		gallium_enable video_cards_amdgpu radeonsi

		# Freedreno code
		gallium_enable video_cards_freedreno freedreno

		gallium_enable video_cards_virgl virgl
	fi

	if use vulkan; then
		vulkan_enable video_cards_intel intel
		vulkan_enable video_cards_amdgpu amd
	fi

	LLVM_ENABLE=false
	if use llvm && use !video_cards_softpipe; then
		emesonargs+=( -Dshared-llvm=false )
		export LLVM_CONFIG=${SYSROOT}/usr/lib/llvm/bin/llvm-config-host
		LLVM_ENABLE=true
	fi

	local egl_platforms=""
	if use egl; then
		if use wayland; then
			egl_platforms="${egl_platforms},wayland"
		fi

		if use X; then
			egl_platforms="${egl_platforms},x11"
		fi
	fi
	egl_platforms="${egl_platforms##,}"

	if use X; then
		glx="dri"
	else
		glx="disabled"
	fi

	if use kvm_guest; then
		emesonargs+=( -Ddri-search-path=/opt/google/cros-containers/lib )
	fi

	emesonargs+=(
		-Dexecmem=false
		-Dglvnd=$(usex libglvnd true false)
		-Dglx="${glx}"
		-Dllvm="${LLVM_ENABLE}"
		-Dplatforms="${egl_platforms}"
		-Dprefer-iris=false
		-Dshader-cache-default=false
		$(meson_feature egl)
		$(meson_feature gbm)
		$(meson_feature gles1)
		$(meson_feature gles2)
		$(meson_use selinux)
		-Ddri-drivers=$(driver_list "${DRI_DRIVERS[*]}")
		-Dgallium-drivers=$(driver_list "${GALLIUM_DRIVERS[*]}")
		-Dvulkan-drivers=$(driver_list "${VULKAN_DRIVERS[*]}")
		--buildtype $(usex debug debug release)
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	# Remove redundant GLES headers
	rm -f "${D}"/usr/include/{EGL,GLES2,GLES3,KHR}/*.h || die "Removing GLES headers failed."

	dodir /usr/$(get_libdir)/dri
	insinto "/usr/$(get_libdir)/dri/"
	insopts -m0755
	# install the gallium drivers we use
	local gallium_drivers_files=( nouveau_dri.so r300_dri.so r600_dri.so msm_dri.so swrast_dri.so )
	for x in ${gallium_drivers_files[@]}; do
		if [ -f "${S}/$(get_libdir)/gallium/${x}" ]; then
			doins "${S}/$(get_libdir)/gallium/${x}"
		fi
	done

	# install classic drivers we use
	local classic_drivers_files=( i810_dri.so i965_dri.so nouveau_vieux_dri.so radeon_dri.so r200_dri.so )
	for x in ${classic_drivers_files[@]}; do
		if [ -f "${S}/$(get_libdir)/${x}" ]; then
			doins "${S}/$(get_libdir)/${x}"
		fi
	done

	# Set driconf option to enable S3TC hardware decompression
	insinto "/etc/"
	doins "${FILESDIR}"/drirc
}

# $1 - VIDEO_CARDS flag (check skipped for "--")
# other args - names of DRI drivers to enable
dri_driver_enable() {
	if [[ $1 == -- ]] || use $1; then
		shift
		DRI_DRIVERS+=("$@")
	fi
}

gallium_enable() {
	if [[ $1 == -- ]] || use $1; then
		shift
		GALLIUM_DRIVERS+=("$@")
	fi
}

vulkan_enable() {
	if [[ $1 == -- ]] || use $1; then
		shift
		VULKAN_DRIVERS+=("$@")
	fi
}
