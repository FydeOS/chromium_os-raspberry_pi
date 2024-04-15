# Copyright 2015 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit eutils libtool flag-o-matic gnuconfig multilib

DESCRIPTION="Tools necessary to build programs"
HOMEPAGE="http://sources.redhat.com/binutils/"
LICENSE="|| ( GPL-3 LGPL-3 )"
IUSE="cet cros_host hardened gprofng multitarget nls test vanilla"

# Variables that can be set here  (ignored for live ebuilds)
# PATCH_VER          - the patchset version
#                      Default: empty, no patching
# PATCH_BINUTILS_VER - the binutils version in the patchset name
#                    - Default: PV
# PATCH_DEV          - Use download URI https://dev.gentoo.org/~{PATCH_DEV}/distfiles/...
#                      for the patchsets
PATCH_VER=5
PATCH_DEV=dilfridge
PATCH_BINUTILS_VER=${PATCH_BINUTILS_VER:-${PV}}
PATCH_DEV=${PATCH_DEV:-slyfox}

KEYWORDS="*"

#
# The cross-compile logic
#
export CTARGET="${CTARGET:-${CHOST}}"
if [[ "${CTARGET}" == "${CHOST}" ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi
is_cross() { [[ "${CHOST}" != "${CTARGET}" ]] ; }

if is_cross ; then
	SLOT="${CTARGET}"
else
	SLOT="0"
fi

SRC_URI="mirror://gnu/binutils/binutils-${PV}.tar.xz
	https://dev.gentoo.org/~${PATCH_DEV}/distfiles/binutils-${PATCH_BINUTILS_VER}-patches-${PATCH_VER}.tar.xz"

BDEPEND="
	sys-devel/gcc
	sys-apps/texinfo
"
RDEPEND=">=sys-devel/binutils-config-3"
DEPEND="${RDEPEND}
	test? ( dev-util/dejagnu )
	nls? ( sys-devel/gettext )
	sys-devel/flex"

RESTRICT="!test? ( test )"

# Disable split debug for cross-<abi>/binutils because
# of race in installing .debug build-id files (b/187790168).
if [[ ${CATEGORY} == cross-* ]]; then
	RESTRICT+=" splitdebug"
fi

MY_BUILDDIR="${WORKDIR}"/build

toolchain-binutils_bugurl() {
	printf "https://crbug.com"
}

src_unpack() {
	if [[ ${PV} == 9999* ]] ; then
		EGIT_REPO_URI="https://anongit.gentoo.org/git/proj/toolchain/binutils-patches.git"
		export EGIT_CHECKOUT_DIR=${WORKDIR}/patches-git
		git-r3_src_unpack
		mv patches-git/9999 patch || die

		export EGIT_REPO_URI="https://sourceware.org/git/binutils-gdb.git"
		S=${WORKDIR}/binutils
		EGIT_CHECKOUT_DIR=${S}
		git-r3_src_unpack
	else
		unpack ${P}.tar.xz

		cd "${WORKDIR}" || die
		unpack "binutils-${PATCH_BINUTILS_VER}-patches-${PATCH_VER}.tar.xz"
	fi

	cd "${WORKDIR}" || die
	mkdir -p "${MY_BUILDDIR}" || die
}

src_prepare() {
	local patchsetname
	if [[ "${PV}" == 9999* ]] ; then
		patchsetname="from git master"
	else
		patchsetname="${PATCH_BINUTILS_VER}-${PATCH_VER}"
	fi

	if [[ -n "${PATCH_VER}" ]] || [[ "${PV}" == 9999* ]] ; then
		if ! use vanilla; then
			einfo "Applying binutils patchset ${patchsetname}"
			eapply "${WORKDIR}/patch"
			einfo "Done."
		fi
	fi

	einfo "Applying local CrOS patches"
	eapply "${FILESDIR}"
	einfo "Done."

	# This check should probably go somewhere else, like pkg_pretend.
	if [[ ${CTARGET} == *-uclibc* ]] ; then
		if grep -qs 'linux-gnu' "${S}"/ltconfig ; then
			die "sorry, but this binutils doesn't yet support uClibc :("
		fi
	fi

	# Make sure our explicit libdir paths don't get clobbered. #562460
	sed -i \
		-e 's:@bfdlibdir@:@libdir@:g' \
		-e 's:@bfdincludedir@:@includedir@:g' \
		{bfd,opcodes}/Makefile.in || die

	# Fix locale issues if possible #122216
	if [[ -e ${FILESDIR}/binutils-configure-LANG.patch ]] ; then
		einfo "Fixing misc issues in configure files"
		# shellcheck disable=SC2044 # this is safe enough as used upstream
		for f in $(find "${S}" -name configure -exec grep -l 'autoconf version 2.13' {} +) ; do
			ebegin "  Updating ${f/${S}\/}"
			patch "${f}" "${FILESDIR}"/binutils-configure-LANG.patch >& "${T}"/configure-patch.log \
				|| eerror "Please file a bug about this"
			eend $?
		done
	fi

	# Fix conflicts with newer glibc #272594
	if [[ -e libiberty/testsuite/test-demangle.c ]] ; then
		sed -i 's:\<getline\>:get_line:g' libiberty/testsuite/test-demangle.c
	fi

	# Apply things from PATCHES and user dirs
	default

	# Run misc portage update scripts
	gnuconfig_update
	elibtoolize --portage --no-uclibc
}

src_configure() {
	export LIBPATH=/usr/$(get_libdir)/binutils/${CTARGET}/${PV}
	export INCPATH=${LIBPATH}/include
	export DATAPATH=/usr/share/binutils-data/${CTARGET}/${PV}

	if is_cross ; then
		export BINPATH=/usr/${CHOST}/${CTARGET}/binutils-bin/${PV}
	else
		export BINPATH=/usr/${CTARGET}/binutils-bin/${PV}
	fi

	cros_optimize_package_for_speed

	# Use gcc to build binutils.
	cros_use_gcc
  filter-flags -mfpu=neon-fp-armv8 -mfloat-abi=hard

	# make sure we filter $LINGUAS so that only ones that
	# actually work make it through #42033
	strip-linguas -u -- */po

	# keep things sane
	strip-flags
	# Use shared libgcc on non-host builds.
	use cros_host || append-ldflags "-shared-libgcc -lpthread"

	local x
	echo
	for x in CATEGORY CBUILD CHOST CTARGET CFLAGS LDFLAGS ; do
		einfo "$(printf '%10s' ${x}:) ${!x}"
	done
	echo

	cd "${MY_BUILDDIR}" || die

	local myconf=( --enable-plugins )

	# enable only the DWP tool which is part of gold, but don't
	# install the gold linker because it is deprecated.
	use cros_host && myconf+=( --enable-gold=dwp )

	use nls \
		&& myconf+=( --without-included-gettext ) \
		|| myconf+=( --disable-nls )

	myconf+=( --enable-64-bit-bfd )

	[[ -n ${CBUILD} ]] && myconf+=( --build="${CBUILD}" )
	is_cross && myconf+=(
		--with-sysroot="${EPREFIX}/usr/${CTARGET}"
		--enable-poison-system-directories
	)

	# shellcheck disable=SC2206 # assignments like EXTRA_ECONF+=" --foo --bar "
	myconf+=(
		--prefix="${EPREFIX}"/usr
		--host="${CHOST}"
		--target="${CTARGET}"
		--datadir="${EPREFIX}${DATAPATH}"
		--infodir="${EPREFIX}${DATAPATH}"/info
		--mandir="${EPREFIX}${DATAPATH}"/man
		--bindir="${EPREFIX}${BINPATH}"
		--libdir="${EPREFIX}${LIBPATH}"
		--libexecdir="${EPREFIX}${LIBPATH}"
		--includedir="${EPREFIX}${INCPATH}"
		--enable-compressed-debug-sections=none
		--enable-threads
		--enable-shared
		--enable-deterministic-archives
		--enable-install-libiberty
		--enable-secureplt
		--disable-werror
		--with-bugurl="$(toolchain-binutils_bugurl)"
		${EXTRA_ECONF}
		# Disable modules that are in a combined binutils/gdb tree. #490566
		--disable-{gdb,libdecnumber,readline,sim}
		# Strip out broken static link flags.
		# https://gcc.gnu.org/PR56750
		--without-stage1-ldflags
		# Allow user to opt into CET for host libraries.
		# Ideally we would like automagic-or-disabled here.
		# But the check does not quite work on i686: bug #760926.
		$(use_enable cet)

		# We can enable this by default in future, but it's brand new
		# in 2.39 with several bugs:
		# - Doesn't build on musl (https://sourceware.org/bugzilla/show_bug.cgi?id=29477)
		# - No man pages (https://sourceware.org/bugzilla/show_bug.cgi?id=29521)
		# - Broken at runtime without Java (https://sourceware.org/bugzilla/show_bug.cgi?id=29479)
		# - binutils-config (and this ebuild?) needs adaptation first (https://bugs.gentoo.org/865113)
		$(use_enable gprofng)
	)

	# Set GNU hash style as a default for all targets except mips.
	# For mips targets, GNU hash cannot work due to ABI constraints.
	[[ "${CTARGET}" != mips* ]] && myconf+=( --enable-default-hash-style=gnu )

	echo ./configure "${myconf[@]}"
	"${S}"/configure "${myconf[@]}" || die
}

src_compile() {
	cd "${MY_BUILDDIR}" || die
	emake all

	# only build info pages if we user wants them, and if
	# we have makeinfo (may not exist when we bootstrap)
	if type -p makeinfo > /dev/null ; then
		emake info
	fi
	# we nuke the manpages when we're left with junk
	# (like when we bootstrap, no perl -> no manpages)
	find . -name '*.1' -a -size 0 -delete
}

src_test() {
	cd "${MY_BUILDDIR}" || die
	emake -k check
}

src_install() {
	local x d

	cd "${MY_BUILDDIR}" || die
	emake DESTDIR="${D}" tooldir="${LIBPATH}" install
	rm -rf "${D}/${LIBPATH}"/bin

	# Newer versions of binutils get fancy with ${LIBPATH} #171905
	cd "${D}/${LIBPATH}" || die
	for d in ../* ; do
		[[ "${d}" == ../"${PV}" ]] && continue
		mv "${d}"/* . || die
		rmdir "${d}" || die
	done

	# Now we collect everything intp the proper SLOT-ed dirs
	# When something is built to cross-compile, it installs into
	# /usr/$CHOST/ by default ... we have to 'fix' that :)
	if is_cross ; then
		cd "${D}/${BINPATH}" || die
		for x in * ; do
			mv "${x}" "${x/${CTARGET}-}" || die
		done

		if [[ -d "${D}/usr/${CHOST}/${CTARGET}" ]] ; then
			mv "${D}/usr/${CHOST}/${CTARGET}"/include "${D}/${INCPATH}"
			mv "${D}/usr/${CHOST}/${CTARGET}"/lib/* "${D}/${LIBPATH}/"
			rm -r "${D}/usr/${CHOST}"/{include,lib}
		fi
	fi
	insinto "${INCPATH}"
	doins "${S}/include/libiberty.h"
	if [[ -d ${D}/${LIBPATH}/lib ]] ; then
		mv "${D}/${LIBPATH}"/lib/* "${D}/${LIBPATH}"/ || die
		rm -r "${D}/${LIBPATH}"/lib
	fi

	# Now, some binutils are tricky and actually provide
	# for multiple TARGETS.  Really, we're talking just
	# 32bit/64bit support (like mips/ppc/sparc).  Here
	# we want to tell binutils-config that it's cool if
	# it generates multiple sets of binutil symlinks.
	# e.g. sparc gets {sparc,sparc64}-unknown-linux-gnu
	local targ=${CTARGET/-*} src="" dst=""
	local FAKE_TARGETS="${CTARGET}"
	case ${targ} in
		mips*)    src="mips"    dst="mips64";;
		powerpc*) src="powerpc" dst="powerpc64";;
		s390*)    src="s390"    dst="s390x";;
		sparc*)   src="sparc"   dst="sparc64";;
	esac
	case ${targ} in
		mips64*|powerpc64*|s390x*|sparc64*) targ=${src} src=${dst} dst=${targ};;
	esac
	[[ -n ${src}${dst} ]] && FAKE_TARGETS="${FAKE_TARGETS} ${CTARGET/${src}/${dst}}"

	# Generate an env.d entry for this binutils
	insinto /etc/env.d/binutils
	cat <<-EOF > "${T}"/env.d
	TARGET="${CTARGET}"
	VER="${PV}"
	LIBPATH="${LIBPATH}"
	FAKE_TARGETS="${FAKE_TARGETS}"
	EOF
	newins "${T}"/env.d "${CTARGET}-${PV}"

	# Handle documentation
	if ! is_cross ; then
		cd "${S}" || die
		dodoc README
		docinto bfd
		dodoc bfd/ChangeLog* bfd/README bfd/PORTING bfd/TODO
		docinto binutils
		dodoc binutils/ChangeLog binutils/NEWS binutils/README
		docinto gas
		dodoc gas/ChangeLog* gas/CONTRIBUTORS gas/NEWS gas/README*
		docinto gprof
		dodoc gprof/ChangeLog* gprof/TEST gprof/TODO gprof/bbconv.pl
		docinto ld
		dodoc ld/ChangeLog* ld/README ld/NEWS ld/TODO
		docinto libiberty
		dodoc libiberty/ChangeLog* libiberty/README
		docinto opcodes
		dodoc opcodes/ChangeLog*
	fi
	# Remove shared info pages
	rm -f "${D}/${DATAPATH}"/info/{dir,configure.info,standards.info}
	# Trim all empty dirs
	find "${D}" -type d -print0 | xargs -0 rmdir >& /dev/null

	if use hardened ; then
		LDWRAPPER=ldwrapper.hardened
		LDWRAPPER_LLD=ldwrapper_lld.hardened
	else
		LDWRAPPER=ldwrapper
		LDWRAPPER_LLD=ldwrapper_lld
	fi

	mv "${D}/${BINPATH}/ld.bfd" "${D}/${BINPATH}/ld.bfd.real" || die
	exeinto "${BINPATH}"
	newexe "${FILESDIR}/${LDWRAPPER}" "ld.bfd" || die

	# Set default to be ld.bfd in regular installation
	dosym ld.bfd "${BINPATH}/ld"

	# Install lld wrapper only for cross toolchains.
	is_cross && newbin "${FILESDIR}/${LDWRAPPER_LLD}" "${CTARGET}-ld.lld"

	# Move the locale directory to where it is supposed to be
	mv "${D}/usr/share/locale" "${D}/${DATAPATH}/"
}

pkg_postinst() {
	binutils-config "${CTARGET}-${PV}"
}

pkg_postrm() {
	local current_profile=$(binutils-config -c "${CTARGET}")

	# If no other versions exist, then uninstall for this
	# target ... otherwise, switch to the newest version
	# Note: only do this if this version is unmerged.  We
	#       rerun binutils-config if this is a remerge, as
	#       we want the mtimes on the symlinks updated (if
	#       it is the same as the current selected profile)
	if [[ ! -e ${BINPATH}/ld ]] && [[ ${current_profile} == ${CTARGET}-${PV} ]] ; then
		local choice=$(binutils-config -l | grep "${CTARGET}" | awk '{print $2}')
		choice=${choice//$'\n'/ }
		choice=${choice/* }
		if [[ -z ${choice} ]] ; then
			binutils-config -u "${CTARGET}"
		else
			binutils-config "${choice}"
		fi
	elif [[ $(CHOST=${CTARGET} binutils-config -c) == ${CTARGET}-${PV} ]] ; then
		binutils-config "${CTARGET}-${PV}"
	fi
}
