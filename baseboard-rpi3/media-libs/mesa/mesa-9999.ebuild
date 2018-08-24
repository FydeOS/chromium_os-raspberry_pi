# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/mesa/mesa-7.9.ebuild,v 1.3 2010/12/05 17:19:14 arfrever Exp $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_BLACKLIST="1"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit base autotools multilib flag-o-matic python toolchain-funcs ${GIT_ECLASS} cros-workon

OPENGL_DIR="xorg-x11"

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
KEYWORDS="~*"

INTEL_CARDS="intel"
RADEON_CARDS="amdgpu radeon"
VIDEO_CARDS="${INTEL_CARDS} ${RADEON_CARDS} freedreno llvmpipe mach64 mga nouveau r128 radeonsi savage sis softpipe tdfx via virgl vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	+classic debug dri egl +gallium -gbm gles1 gles2 llvm +nptl pic selinux
	shared-glapi kernel_FreeBSD vulkan wayland xlib-glx X"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.60"

REQUIRED_USE="video_cards_amdgpu? ( llvm )
	video_cards_llvmpipe? ( llvm )"

# keep correct libdrm and dri2proto dep
# keep blocks in rdepend for binpkg
RDEPEND="
	X? (
		!<x11-base/xorg-server-1.7
		!<=x11-proto/xf86driproto-2.0.3
		>=x11-libs/libX11-1.3.99.901
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXxf86vm
	)
	dev-libs/expat
	dev-libs/libgcrypt
	virtual/udev
	${LIBDRM_DEPSTRING}
"

DEPEND="${RDEPEND}
	=dev-lang/python-2*
	dev-libs/libxml2
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	>=x11-proto/dri2proto-2.6
	wayland? ( >=dev-libs/wayland-protocols-1.8 )
	X? (
		>=x11-proto/glproto-1.4.11
		>=x11-proto/xextproto-7.0.99.1
		x11-proto/xf86driproto
		x11-proto/xf86vidmodeproto
	)
	llvm? ( sys-devel/llvm )
"

# It is slow without texrels, if someone wants slow
# mesa without texrels +pic use is worth the shot
QA_EXECSTACK="usr/lib*/opengl/xorg-x11/lib/libGL.so*"
QA_WX_LOAD="usr/lib*/opengl/xorg-x11/lib/libGL.so*"

# Think about: ggi, fbcon, no-X configs

pkg_setup() {
	# workaround toc-issue wrt #386545
	use ppc64 && append-flags -mminimal-toc
}

src_prepare() {
	# apply patches
	if [[ ${PV} != 9999* && -n ${SRC_PATCHES} ]]; then
		EPATCH_FORCE="yes" \
		EPATCH_SOURCE="${WORKDIR}/patches" \
		EPATCH_SUFFIX="patch" \
		epatch
	fi
	# FreeBSD 6.* doesn't have posix_memalign().
	if [[ ${CHOST} == *-freebsd6.* ]]; then
		sed -i \
			-e "s/-DHAVE_POSIX_MEMALIGN//" \
			configure.ac || die
	fi

	epatch "${FILESDIR}"/9.1-mesa-st-no-flush-front.patch
	epatch "${FILESDIR}"/8.1-array-overflow.patch
	epatch "${FILESDIR}"/10.3-dri-i965-Return-NULL-if-we-don-t-have-a-miptree.patch
	epatch "${FILESDIR}"/10.3-drivers-dri-i965-gen6-Clamp-scissor-state-instead-of.patch
	epatch "${FILESDIR}"/17.0-glcpp-Hack-to-handle-expressions-in-line-di.patch
	epatch "${FILESDIR}"/17.3-virgl-also-remove-dimension-on-indirect.patch
	epatch "${FILESDIR}"/17.3-virgl-Support-v2-caps-struct-v2.patch
	epatch "${FILESDIR}"/17.3-mesa-don-t-clamp-just-based-on-ARB_viewport_array-ex.patch
	epatch "${FILESDIR}"/17.3-virgl-remap-query-types-to-hw-support.patch
	epatch "${FILESDIR}"/17.3-virgl-handle-getting-new-capsets.patch
	epatch "${FILESDIR}"/17.3-virgl-reduce-some-default-capset-limits.patch
	epatch "${FILESDIR}"/17.3-virgl-add-offset-alignment-values-to-to-v2-caps-stru.patch
	epatch "${FILESDIR}"/17.3-virgl-Implement-seamless-cube-maps.patch
	epatch "${FILESDIR}"/17.3-gallium-winsys-kms-Fix-possible-leak-in-map-unmap.patch
	epatch "${FILESDIR}"/17.3-gallium-winsys-kms-Add-support-for-multi-planes.patch
	epatch "${FILESDIR}"/18.1-mesa-add-xbgr-support-adjacent-to-xrgb.patch
	epatch "${FILESDIR}"/18.1-amdgpu-always-allow-GTT-placements-on-APUs.patch
	epatch "${FILESDIR}"/18.1-dri_util-Add-R10G10B10-A-X-2-translation-between_DRI.patch
	epatch "${FILESDIR}"/18.1-i965-add-X-A-BGR2101010-to-intel_image_formats.patch
	base_src_prepare

	# Produce a dummy git_sha1.h file because .git will not be copied to portage tmp directory
	echo '#define MESA_GIT_SHA1 "git-0000000"' > src/git_sha1.h

	eautoreconf
}

src_configure() {
	tc-getPROG PKG_CONFIG pkg-config

	# Needs std=gnu++11 to build with libc++. crbug.com/750831
	append-cxxflags "-std=gnu++11"

	# For llvmpipe on ARM we'll get errors about being unable to resolve
	# "__aeabi_unwind_cpp_pr1" if we don't include this flag; seems wise
	# to include it for all platforms though.
	use video_cards_llvmpipe && append-flags "-rtlib=libgcc"

	if use !gallium && use !classic && use !vulkan; then
		ewarn "You enabled neither classic, gallium, nor vulkan "
		ewarn "USE flags. No hardware drivers will be built."
	fi

	if use classic; then
	# Configurable DRI drivers
		# Intel code
		driver_enable video_cards_intel i965
	fi

	if use gallium; then
	# Configurable gallium drivers
		gallium_driver_enable video_cards_llvmpipe swrast
		gallium_driver_enable video_cards_softpipe swrast

		# Nouveau code
		gallium_driver_enable video_cards_nouveau nouveau

		# ATI code
		gallium_driver_enable video_cards_radeon r300 r600
		gallium_driver_enable video_cards_amdgpu radeonsi

		# Freedreno code
		gallium_driver_enable video_cards_freedreno freedreno

		gallium_driver_enable video_cards_virgl virgl
	fi

	if use vulkan; then
		if use video_cards_intel; then
			VULKAN_DRIVERS+=",intel"
		fi
		if use video_cards_amdgpu; then
			VULKAN_DRIVERS+=",radeon"
		fi
	fi

	LLVM_ENABLE="--disable-llvm"
	if use llvm && use !video_cards_softpipe; then
		export LLVM_CONFIG=${SYSROOT}/usr/bin/llvm-config-host
		LLVM_ENABLE="--enable-llvm"
	fi

	local egl_platforms=""
	if use egl; then
		egl_platforms="--with-platforms=surfaceless"

		if use X; then
			egl_platforms="${egl_platforms},x11"
		fi

		if use wayland; then
			egl_platforms="${egl_platforms},wayland"
		fi
	fi

	# --with-driver=dri|xlib|osmesa || do we need osmesa?
	econf \
		--disable-option-checking \
		--with-driver=dri \
		--disable-glu \
		--disable-glut \
		--disable-omx-bellagio \
		--disable-va \
		--disable-vdpau \
		--disable-xvmc \
		--without-demos \
		--enable-texture-float \
		--disable-dri3 \
		--disable-llvm-shared-libs \
		$(use_enable X glx) \
		$(use_enable egl) \
		$(use_enable gbm) \
		$(use_enable gles1) \
		$(use_enable gles2) \
		$(use_enable shared-glapi) \
		$(use_enable gallium) \
		$(use_enable debug) \
		$(use_enable nptl glx-tls) \
		$(use_enable !pic asm) \
		$(use_enable xlib-glx) \
		$(use_enable !xlib-glx dri) \
		--with-dri-drivers=${DRI_DRIVERS} \
		--with-gallium-drivers=${GALLIUM_DRIVERS} \
		--with-vulkan-drivers=${VULKAN_DRIVERS} \
		${LLVM_ENABLE} \
		"${egl_platforms}"
}

src_install() {
	base_src_install

	# Remove redundant GLES headers
	rm -f "${D}"/usr/include/{EGL,GLES2,GLES3,KHR}/*.h || die "Removing GLES headers failed."

	# Move libGL and others from /usr/lib to /usr/lib/opengl/blah/lib
	# because user can eselect desired GL provider.
	ebegin "Moving libGL and friends for dynamic switching"
		dodir /usr/$(get_libdir)/opengl/${OPENGL_DIR}/{lib,extensions,include}
		local x
		for x in "${D}"/usr/$(get_libdir)/libGL.{la,a,so*}; do
			if [ -f ${x} -o -L ${x} ]; then
				mv -f "${x}" "${D}"/usr/$(get_libdir)/opengl/${OPENGL_DIR}/lib \
					|| die "Failed to move ${x}"
			fi
		done
		for x in "${D}"/usr/include/GL/{gl.h,glx.h,glext.h,glxext.h}; do
			if [ -f ${x} -o -L ${x} ]; then
				mv -f "${x}" "${D}"/usr/$(get_libdir)/opengl/${OPENGL_DIR}/include \
					|| die "Failed to move ${x}"
			fi
		done
	eend $?

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

pkg_postinst() {
	# Switch to the xorg implementation.
	echo
	eselect opengl set --use-old ${OPENGL_DIR}
}

# $1 - VIDEO_CARDS flag
# other args - names of DRI drivers to enable
driver_enable() {
	case $# in
		# for enabling unconditionally
		1)
			DRI_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					DRI_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}

# $1 - VIDEO_CARDS flag
# other args - names of DRI drivers to enable
gallium_driver_enable() {
	case $# in
		# for enabling unconditionally
		1)
			GALLIUM_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					GALLIUM_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}
