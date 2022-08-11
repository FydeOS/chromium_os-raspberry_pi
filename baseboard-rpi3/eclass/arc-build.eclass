# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: arc-build.eclass
# @MAINTAINER:
# Chromium OS Build Team
# @BUGREPORTS:
# Please report bugs via http://crbug.com/new (with label Build)
# @VCSURL: https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/eclass/@ECLASS@
# @BLURB: helper eclass for building packages to run under ARC (Android Runtime)
# @DESCRIPTION:
# We want to build some libraries to run under ARC.  These funcs will help
# write ebuilds to accomplish that.

# @ECLASS-VARIABLE: ARC_BASE
# @DESCRIPTION:
# The path to ARC toolchain root directory. Normally defined by the profile.
# e.g. /opt/android-master, for sys-devel/arc-toolchain-master

# @ECLASS-VARIABLE: ARC_VERSION_MAJOR
# @DESCRIPTION:
# Major version of Android that was used to generate the ARC toolchain.
# Normally defined by the profile. e.g. 7, for Android 7.1.0

# @ECLASS-VARIABLE: ARC_VERSION_MINOR
# @DESCRIPTION:
# Minor version of Android that was used to generate the ARC toolchain.
# Normally defined by the profile. e.g. 1, for Android 7.1.0

# @ECLASS-VARIABLE: ARC_VERSION_PATCH
# @DESCRIPTION:
# Minor version of Android that was used to generate the ARC toolchain.
# Normally defined by the profile. e.g. 0, for Android 7.1.0

# @ECLASS-VARIABLE: ARC_LLVM_VERSION
# @DESCRIPTION:
# Version of LLVM included in the ARC toolchain.
# Normally defined by the profile, e.g. 3.8

if [[ -z ${_ARC_BUILD_ECLASS} ]]; then
_ARC_BUILD_ECLASS=1

# Check for EAPI 4+.
case "${EAPI:-0}" in
4|5|6|7) ;;
*) die "unsupported EAPI (${EAPI}) in eclass (${ECLASS})" ;;
esac

inherit multilib-build flag-o-matic cros-constants arc-build-constants

DEPEND="sys-devel/arc-build[${MULTILIB_USEDEP}]"

# Make sure we know how to handle the active system.
arc-build-check-arch() {
	case ${ARCH} in
	arm|arm64|amd64) ;;
	*) die "Unsupported arch ${ARCH}" ;;
	esac
}

arc-build-select-clang() {
	if [[ -n ${ARC_SYSROOT} ]] ; then
		# If we've already been set up, don't re-run.
		die "arc-build must be initialized only once. Please fix your ebuild."
	fi

	arc-build-constants-configure
	arc-build-check-arch

	export ARC_SYSROOT="${SYSROOT}${ARC_PREFIX}"
	export PKG_CONFIG="${ARC_SYSROOT}/build/bin/pkg-config"

	case ${ARCH} in
	arm|arm64)
		ARC_GCC_TUPLE_arm64=aarch64-linux-android
		ARC_GCC_BASE_arm64="${ARC_BASE}/arc-gcc/aarch64/${ARC_GCC_TUPLE_arm64}-4.9"
		ARC_GCC_TUPLE_arm=arm-linux-androideabi
		ARC_GCC_BASE_arm="${ARC_BASE}/arc-gcc/arm/${ARC_GCC_TUPLE_arm}-4.9"

		# multilib.eclass does not use CFLAGS_${DEFAULT_ABI}, but
		# we need to add some flags valid only for arm/arm64, so we trick
		# it to think that neither arm nor arm64 is the default.
		export DEFAULT_ABI=none
		export CHOST=aarch64-linux-android
		export CHOST_arm64=aarch64-linux-android
		export CHOST_arm=armv7-linux-androideabi

		# Android uses softfp ABI
		filter-flags -mfloat-abi=hard
		CFLAGS_arm="${CFLAGS_arm} -mfloat-abi=softfp"

		CFLAGS_arm64="${CFLAGS_arm64} -I${ARC_SYSROOT}/usr/include/arch-arm64/include/"
		CFLAGS_arm="${CFLAGS_arm} -I${ARC_SYSROOT}/usr/include/arch-arm/include/"

		export CFLAGS_arm64="${CFLAGS_arm64} -target ${CHOST_arm64} --gcc-toolchain=${ARC_GCC_BASE_arm64}"
		export CFLAGS_arm="${CFLAGS_arm} -target ${CHOST_arm} --gcc-toolchain=${ARC_GCC_BASE_arm}"

		# Add Android related utilities location to ${PATH}.
		export PATH="${ARC_GCC_BASE_arm64}/bin:${ARC_GCC_BASE_arm}/bin:${PATH}"
		;;
	amd64)
		ARC_GCC_TUPLE=x86_64-linux-android
		ARC_GCC_BASE="${ARC_BASE}/arc-gcc/x86_64/${ARC_GCC_TUPLE}-4.9"

		# Old versions of clang cannot recognize new CPU flags. Replace
		# them with the latest Atom available on each version.
		case ${ARC_VERSION_MAJOR} in
		9)
		# ARC P uses llvm 6.0
			replace-flags -march=goldmont-plus -march=goldmont
			replace-flags -march=tremont -march=goldmont
			replace-flags -march=alderlake -march=goldmont
			;;
		11)
		# ARC R uses llvm 11.0.2
			replace-flags -march=alderlake -march=tremont
			;;
		esac

		# multilib.eclass does not use CFLAGS_${DEFAULT_ABI}, but
		# we need to add some flags valid only for amd64, so we trick
		# it to think that neither x86 nor amd64 is the default.
		export DEFAULT_ABI=none
		export CHOST=x86_64-linux-android
		export CHOST_amd64=x86_64-linux-android
		export CHOST_x86=i686-linux-android

		CFLAGS_amd64="${CFLAGS_amd64} -I${ARC_SYSROOT}/usr/include/arch-x86_64/include/"
		CFLAGS_x86="${CFLAGS_x86} -I${ARC_SYSROOT}/usr/include/arch-x86/include/"

		export CFLAGS_amd64="${CFLAGS_amd64} -target ${CHOST_amd64} --gcc-toolchain=${ARC_GCC_BASE}"
		export CFLAGS_x86="${CFLAGS_x86} -target ${CHOST_x86} --gcc-toolchain=${ARC_GCC_BASE}"

		# Add Android related utilities location to ${PATH}.
		export PATH="${ARC_GCC_BASE}/bin:${PATH}"
		;;
	esac

	# Make sure we use the 64-bit strip/objcopy that can handle both 32-bit
	# and 64-bit binaries.
	STRIP="$(tc-getSTRIP ${CHOST})"
	export STRIP
	OBJCOPY="$(tc-getOBJCOPY ${CHOST})"
	export OBJCOPY

	# Some linkers (namely ARM64's bfd linker) do no have this flag set by
	# default.
	append-ldflags -Wl,--allow-shlib-undefined

	# Strip out flags that are specific to our compiler wrapper.
	filter-flags -clang-syntax

	# Some linkers (such as ARM64's bfd linker) doesn't recognize or link
	# correctly with this flag, filter it out.
	filter-flags -Wl,--icf=all

	# Ignore unwindlib flag for ARC++.
	filter-flags --unwindlib=libunwind

	# Set up flags for the android sysroot.
	append-flags --sysroot="${ARC_SYSROOT}"
	append-cppflags --sysroot="${ARC_SYSROOT}"
	local android_version=$(printf "0x%04x" \
		$(((ARC_VERSION_MAJOR << 8) + ARC_VERSION_MINOR)))
	append-cppflags -DANDROID -DANDROID_VERSION=${android_version}

	# By default Chrome OS build system adds the CFLAGS/CXXFLAGS as below:
	# -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-table
	# They prevent Android from showing the backtrace.
	# By calling 'cros_enable_cxx_exceptions' we can filter out these flags.
	# Call it here to make sure that any Android packages are compiled this way.
	cros_enable_cxx_exceptions

	# Select clang compiler
	ARC_LLVM_BASE="${ARC_BASE}/arc-llvm/${ARC_LLVM_VERSION}"
	export CC="${ARC_LLVM_BASE}/bin/clang"
	export CXX="${ARC_LLVM_BASE}/bin/clang++"

	# Allow unused arguments since ARC often uses flags from Chrome OS but
	# with older clang.
	append-cflags -Qunused-arguments -Wno-unknown-warning-option
	append-cxxflags -Qunused-arguments -Wno-unknown-warning-option

	if (( ${ARC_VERSION_MAJOR} == 9 )); then
		# TODO(crbug.com/922335): Remove "-stdlib=libc++" after bug resolved.
		export CXX="${CXX} -stdlib=libc++"
		append-cxxflags -stdlib=libc++
	else
		append-cxxflags -nostdinc++ -I${ARC_SYSROOT}/usr/include/c++/4.9
	fi
}

# This is composed after the cross file generated in meson.eclass, and
# values here override values there.
arc-build-create-cross-file() {
	# Reference: http://mesonbuild.com/Cross-compilation.html

	ARC_CROSS_FILE="${T}/arc-meson.${CHOST}.${ABI}"

	# Explicitly prohibit meson from running cross-built binaries.
	#
	# This is done by setting `needs_exe_wrapper` to true and
	# `exe_wrapper` to the empty string.
	#
	# If at some point a wrapper is written that can run ARC
	# binaries this should be updated.

	cat > "${ARC_CROSS_FILE}" <<-EOF
	[binaries]
	exe_wrapper = ''

	[properties]
	needs_exe_wrapper = true

	EOF
}

fi
