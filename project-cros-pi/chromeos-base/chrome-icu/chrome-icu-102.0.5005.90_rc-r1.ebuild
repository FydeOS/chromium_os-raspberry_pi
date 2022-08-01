# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This ebuild is based on "chromeos-chrome.ebuild" to compile the chrome/icu
# package into shared libraries and install them. The essential difference is to
# do "chrome_make icu" rather than "chrome_make chrome". Besides, some other
# non-trivial modifications are:
#   - "chromium-source.eclass" is used to download chrome source code. Because
#     "chromeos-chrome.ebuild" and "chromium-source.eclass" download the chrome
#     source into the same location, the variables of "chromeos-chrome.ebuild"
#     are kept.
#   - "Control-flow integrity" (|is_cfi=false| and |use_cfi_cast=false|) is
#     turned off otherwise the generated .so will crash (Illegal instruction).
#   - Unrelated resource downloads (like for telemetry) are removed.
#   - Unrelated configuration (like ozone platforms) are removed.
#   - Unrelated features (like nacl) are disabled.
#   - Header folders and libraries are postfixed with "${CHROME_ICU_POSTFIX}".
#
# Significant changes from "chromeos-chrome.ebuild" are highlighted by "[Mod]".
#
# The GN output folder is named as "out_icu_${BOARD}".

EAPI=5

PYTHON_COMPAT=( python3_{6..8} )
inherit binutils-funcs chromium-source cros-constants cros-sanitizers flag-o-matic multilib toolchain-funcs python-any-r1 multiprocessing

DESCRIPTION="The ICU library copied from chrome/third_party"
HOMEPAGE="https://cs.chromium.org/chromium/src/third_party/icu/"

LICENSE="icu-58"

SLOT="0/${PVR}"
KEYWORDS="*"

# [Mod] Most of non-related IUSE flags are removed.
IUSE="
	asan
	chrome_internal
	component_build
	cups
	+libcxx
	msan
	neon
	+runhooks
	thinlto
	ubsan
	verbose
	xkbcommon
	"

# [Mod] clear REQUIRED_USE.
REQUIRED_USE=""

# [Mod] Ozone platform variables are removed.

# The gclient hooks that run in src_prepare hit the network.
# https://crbug.com/731905
RESTRICT="network-sandbox mirror"

# Portage version without optional portage suffix.
CHROME_VERSION="${PV/_*/}"

# chrome destination directory
CHROME_DIR=/opt/google/chrome

# For compilation
BUILDTYPE="${BUILDTYPE:-Release}"
BOARD="${BOARD:-${SYSROOT##/build/}}"
# [Mod] GN output dir is named as "out_icu_${BOARD}".
BUILD_OUT="${BUILD_OUT:-out_icu_${BOARD}}"

# [Mod] Change from "c" to avoid potential conflict with chromeos-chrome.ebuild.
BUILD_OUT_SYM="c_icu"

# [Mod] To differentiate with the standard ICU, we postfix the include headers
# folder and library names by "chrome". (see crbug.com/1059133 and b/151439301)
CHROME_ICU_POSTFIX="-chrome"

# [Mod] Order file and AFDO file variables/functions declared here are removed.

# [Mod] chrome/icu depends on nothing. Blocking the canonical icu package can
# let us notice the potential repetitions.
# [Mod] Old Chrome ebuilds installed icudtl.dat.
# Add `xkbcommon` related libraries to make xkbcommon handling identical with
# chromeos-chrome. This will make it more likely to catch potential xkbcommon
# related chromeos-icu.ebuild failures by testing chromeos-chrome.ebuild.
RDEPEND="
	!dev-libs/icu
	!<chromeos-base/chromeos-chrome-83.0.4098.4
	xkbcommon? (
		x11-libs/libxkbcommon
		x11-misc/xkeyboard-config
	)
"
DEPEND="
	net-print/cups
	x11-libs/libdrm
"

# [Mod] NaCl utilities are removed.

usetf()  { usex $1 true false ; }

set_build_args() {
	# [Mod] 1. Add a new arg "icu_disable_thin_archive=true".
	#       2. Set the values according to IUSE default value but disable
	#          unnecessary feature
	#       3. Set "is_cfi=false".
	BUILD_ARGS=(
		"is_chromeos_device=true"
		"icu_disable_thin_archive=true"

		# is_official_build sometimes implies extra optimizations (e.g. it will allow
		# ThinLTO to optimize more aggressively, if ThinLTO is enabled). Please note
		# that, despite the name, it should be usable by external users.
		#
		# Sanitizers don't like official builds.
		"is_official_build=$(use_sanitizers false true)"

		"is_debug=false"
		"${EXTRA_GN_ARGS}"
		"use_ozone=true"
		"use_evdev_gestures=false"
		# Use the Chrome OS toolchain and not the one bundled with Chromium.
		"linux_use_bundled_binutils=false"
		"use_debug_fission=false"
		"enable_remoting=false"
		"enable_nacl=false"
		"enable_nacl=false"
		"icu_use_data_file=true"
		# Add this to make xkbcommon handling identical with chromeos-chrome.
		# This will make it more likely to catch potential xkbcommon related
		# chromeos-icu.ebuild failures by testing chromeos-chrome.ebuild
		"use_xkbcommon=$(usetf xkbcommon)"
		# use_system_minigbm is set below.
		# HarfBuzz and FreeType need to be built together in a specific way
		# to get FreeType autohinting to work properly. Chromium bundles
		# FreeType and HarfBuzz to meet that need.
		# See crbug.com/694137 .
		"use_system_harfbuzz=false"
		"use_system_freetype=false"
		"use_system_libsync=false"
		"use_cups=$(usetf cups)"
		"use_bundled_fontconfig=false"

		# Clang features.
		"is_asan=$(usetf asan)"
		"is_msan=$(usetf msan)"
		"is_ubsan=$(usetf ubsan)"
		"use_thin_lto=$(usetf thinlto)"
		"is_cfi=false"
		"use_cfi_cast=false"
		"use_cras=false"
	)

	# BUILD_STRING_ARGS needs appropriate quoting. So, we keep them separate and
	# add them to BUILD_ARGS at the end.
	BUILD_STRING_ARGS=(
		"target_sysroot=${SYSROOT}"
		"system_libdir=$(get_libdir)"
		"pkg_config=$(tc-getPKG_CONFIG)"
		"target_os=chromeos"
		"host_pkg_config=$(tc-getBUILD_PKG_CONFIG)"
	)

	# [Mod] Ozone platform configrations are removed.

	# Set proper build args for the arch
	case "${ARCH}" in
	x86)
		BUILD_STRING_ARGS+=( "target_cpu=x86" )
		;;
	arm)
		BUILD_ARGS+=(
			"arm_use_neon=$(usetf neon)"
			# To workaround the 4GB debug limit. crbug.com/792999.
			"blink_symbol_level=1"
		)
		BUILD_STRING_ARGS+=(
			"target_cpu=arm"
			"arm_float_abi=hard"
		)
		local arm_arch=$(get-flag march)
		if [[ -n "${arm_arch}" ]]; then
			BUILD_STRING_ARGS+=( "arm_arch=${arm_arch}" )
		fi
		;;
	arm64)
		BUILD_STRING_ARGS+=(
			"target_cpu=arm64"
		)
		local arm_arch=$(get-flag march)
		if [[ -n "${arm_arch}" ]]; then
			BUILD_STRING_ARGS+=( "arm_arch=${arm_arch}" )
		fi
		;;
	amd64)
		BUILD_STRING_ARGS+=( "target_cpu=x64" )
		;;
	mips)
		local mips_arch target_arch

		mips_arch="$($(tc-getCPP) ${CFLAGS} ${CPPFLAGS} -E -P - <<<_MIPS_ARCH)"
		# Strip away any enclosing quotes.
		mips_arch="${mips_arch//\"}"
		# TODO(benchan): Use tc-endian from toolchain-func to determine endianess
		# when Chrome later cares about big-endian.
		case "${mips_arch}" in
		mips64*)
			target_arch=mips64el
			;;
		*)
			target_arch=mipsel
			;;
		esac

		BUILD_STRING_ARGS+=(
			"target_cpu=${target_arch}"
			"mips_arch_variant=${mips_arch}"
		)
		;;
	*)
		die "Unsupported architecture: ${ARCH}"
		;;
	esac

	# [Mod] chrome_media configurations are removed.
	if use chrome_internal; then
		# Adding chrome branding specific variables.
		BUILD_ARGS+=( "is_chrome_branded=true" )
		# This test can only be build from internal sources.
		BUILD_ARGS+=( "internal_gles2_conform_tests=true" )
		export CHROMIUM_BUILD='_google_Chrome'
		export OFFICIAL_BUILD='1'
		export CHROME_BUILD_TYPE='_official'
	fi

	BUILD_ARGS+=(
		"treat_warnings_as_errors=false"
	)

	if use component_build; then
		BUILD_ARGS+=( "is_component_build=true" )
	fi

	# [Mod] goma is disabled.
	BUILD_ARGS+=( "use_goma=false" )

	# [Mod] chrome_debug and debug_fission configurations are removed.
}

# [Mod] Main content of unpack_chrome() is replaced by the unpack function in
# chromium-source.eclass.
unpack_chrome() {
	# Add depot_tools to PATH, local chroot builds fail otherwise.
	export PATH=${PATH}:${DEPOT_TOOLS}

	chromium-source_src_unpack
}

decide_chrome_origin() {
	if [[ "${PV}" == "9999" ]]; then
		# LOCAL_SOURCE is the default for cros_workon
		# Warn the user if CHROME_ORIGIN is already set
		if [[ -n "${CHROME_ORIGIN}" && "${CHROME_ORIGIN}" != LOCAL_SOURCE ]]; then
			ewarn "CHROME_ORIGIN is already set to ${CHROME_ORIGIN}."
			ewarn "This will prevent you from building from your local checkout."
			ewarn "Please run 'unset CHROME_ORIGIN' to reset Chrome"
			ewarn "to the default source location."
		fi
		: "${CHROME_ORIGIN:=LOCAL_SOURCE}"
	else
		# By default, pull from server
		: "${CHROME_ORIGIN:=SERVER_SOURCE}"
	fi
}

sandboxless_ensure_directory() {
	local dir
	for dir in "$@"; do
		if [[ ! -d "${dir}" ]] ; then
			# We need root access to create these directories, so we need to
			# use sudo. This implicitly disables the sandbox.
			sudo mkdir -p "${dir}" || die
			sudo chown "${PORTAGE_USERNAME}:portage" "${dir}" || die
			sudo chmod 0755 "${dir}" || die
		fi
	done
}

src_unpack() {
	tc-export CC CXX
	local WHOAMI=$(whoami)

	CHROME_SRC="chrome-src"
	if use chrome_internal; then
		CHROME_SRC+="-internal"
	fi

	# CHROME_CACHE_DIR is used for storing output artifacts, and is always a
	# regular directory inside the chroot (i.e. it's never mounted in, so it's
	# always safe to use cp -al for these artifacts).
	: "${CHROME_CACHE_DIR:="/var/cache/chromeos-chrome/${CHROME_SRC}"}"
	addwrite "${CHROME_CACHE_DIR}"

	# CHROME_DISTDIR is used for storing the source code, if any source code
	# needs to be unpacked at build time (e.g. in the SERVER_SOURCE scenario.)
	# It will be mounted into the chroot, so it is never safe to use cp -al
	# for these files.
	: "${CHROME_DISTDIR:="${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/${CHROME_SRC}"}"
	addwrite "${CHROME_DISTDIR}"

	# Create storage directories.
	sandboxless_ensure_directory "${CHROME_DISTDIR}" "${CHROME_CACHE_DIR}"

	# [Mod] Calls of cros-credentials_setup is removed.

	decide_chrome_origin

	# [Mod] LOCAL_BINARY is not supported because chromium-source.eclass does not
	# support it.
	case "${CHROME_ORIGIN}" in
	LOCAL_SOURCE|SERVER_SOURCE)
		einfo "CHROME_ORIGIN VALUE is ${CHROME_ORIGIN}"
		;;
	*)
		die "CHROME_ORIGIN not one of LOCAL_SOURCE, SERVER_SOURCE"
		;;
	esac

	# Prepare and set CHROME_ROOT based on CHROME_ORIGIN.
	# CHROME_ROOT is the location where the source code is used for compilation.
	# If we're in SERVER_SOURCE mode, CHROME_ROOT is CHROME_DISTDIR. In LOCAL_SOURCE
	# mode, this directory may be set manually to any directory. It may be mounted
	# into the chroot, so it is not safe to use cp -al for these files.
	# These are set here because $(whoami) returns the proper user here,
	# but 'root' at the root level of the file
	case "${CHROME_ORIGIN}" in
	(SERVER_SOURCE)
		elog "Using CHROME_VERSION = ${CHROME_VERSION}"
		if [[ ${WHOAMI} == "chrome-bot" ]]; then
			# TODO: Should add a sanity check that the version checked out is
			# what we actually want.  Not sure how to do that though.
			elog "Skipping syncing as cbuildbot ran SyncChrome for us."
		else
			unpack_chrome
		fi

		elog "set the chrome source root to ${CHROME_DISTDIR}"
		elog "From this point onwards there is no difference between \
			SERVER_SOURCE and LOCAL_SOURCE, since the fetch is done"
		CHROME_ROOT=${CHROME_DISTDIR}
		;;
	(LOCAL_SOURCE)
		: "${CHROME_ROOT:=/home/${WHOAMI}/chrome_root}"
		if [[ ! -d "${CHROME_ROOT}/src" ]]; then
			die "${CHROME_ROOT} does not contain a valid chromium checkout!"
		fi
		addwrite "${CHROME_ROOT}"
		;;
	esac

	# [Mod] Always call this because the case CHROME_ORIGIN=LOCAL_BINARY is
	# excluded.
	set_build_args

	ln -sf "${CHROME_ROOT}" "${WORKDIR}/${P}"

	# [Mod] Use flags internal_gles_conform, afdo_use, afdo_verify,
	# orderfile_verify and orderfile_use are all disabled.
	BUILD_STRING_ARGS+=( "chrome_orderfile_path=" )
}

# [Mod] add_api_keys() is removed because we do not need to access Google
# services.

# [Mod] src_prepare() is simplied because 1) we do not need to access Google
# services; 2) we exclude the case CHROME_ORIGIN=LOCAL_BINARY and 3) we do
# not need patches.
src_prepare() {
	cd "${CHROME_ROOT}/src" || die "Cannot chdir to ${CHROME_ROOT}"
	mkdir -p "${CHROME_CACHE_DIR}/src/${BUILD_OUT}"
	if [[ -n "${BUILD_OUT_SYM}" ]]; then
		rm -rf "${BUILD_OUT_SYM}" || die "Could not remove symlink"
		ln -sfT "${CHROME_CACHE_DIR}/src/${BUILD_OUT}" "${BUILD_OUT_SYM}" ||
			die "Could not create symlink for output directory"
	fi
}

# [Mod] setup_test_lists() is removed.

# Handle all CFLAGS/CXXFLAGS/etc... munging here.
setup_compile_flags() {
	# Chrome controls its own optimization settings, so this would be a nop
	# if we were to run it. Leave it here anyway as a grep-friendly marker.
	# cros_optimize_package_for_speed

	# The chrome makefiles specify -O and -g flags already, so remove the
	# portage flags.
	filter-flags -g -O*

	# Remove unsupported arm64 linker flag on arm32 builds.
	# https://crbug.com/889079
	use arm && filter-flags "-Wl,--fix-cortex-a53-843419"

	# There are some flags we want to only use in the ebuild.
	# The rest will be exported to the simple chrome workflow.
	EBUILD_CFLAGS=()
	EBUILD_CXXFLAGS=()
	EBUILD_LDFLAGS=()

	# LLVM needs this when parsing profiles.
	# See README on https://github.com/google/autofdo
	# For ARM, we do not need this flag because we don't get profiles
	# from ARM machines. And it triggers an llvm assertion when thinlto
	# and debug fission is used together.
	# See https://bugs.llvm.org/show_bug.cgi?id=37255
	use arm || append-flags -fdebug-info-for-profiling

	if use thinlto; then
		# We need to change the default value of import-instr-limit in
		# LLVM to limit the text size increase. The default value is
		# 100, and we change it to 30 to reduce the text size increase
		# from 25% to 10%. The performance number of page_cycler is the
		# same on two of the thinLTO configurations, we got 1% slowdown
		# on speedometer when changing import-instr-limit from 100 to 30.
		# We need to further reduce it to 20 for arm to limit the size
		# increase to 10%.
		local thinlto_ldflag="-Wl,-plugin-opt,-import-instr-limit=30"
		if use arm; then
			thinlto_ldflag="-Wl,-plugin-opt,-import-instr-limit=20"
			EBUILD_LDFLAGS+=( -gsplit-dwarf )
		fi
		EBUILD_LDFLAGS+=( "${thinlto_ldflag}" )
		# if using thinlto, we need to pass the equivalent of
		# -fdebug-types-section to the backend, to prevent out-of-range
		# relocations (see
		# https://bugs.chromium.org/p/chromium/issues/detail?id=1032159).
		append-ldflags -Wl,-mllvm
		append-ldflags -Wl,-generate-type-units
	fi

	# [Mod] Configurations related to orderfile_generate USE flag are removed.

	# Turn off call graph profile sort (C3), when new pass manager is enabled.
	# Only allow it when we want to generate orderfile.
	# This is a temporary option and will need to be removed once orderfile is on.
	EBUILD_LDFLAGS+=( "-Wl,--no-call-graph-profile-sort" )

	# Enable std::vector []-operator bounds checking.
	append-cxxflags -D__google_stl_debug_vector=1

	# Chrome and Chrome OS versions of the compiler may not be in
	# sync. So, don't complain if Chrome uses a diagnostic
	# option that is not yet implemented in the compiler version used
	# by Chrome OS.
	# Turns out this is only really supported by Clang. See crosbug.com/615466
	# Add "-faddrsig" flag required to efficiently support "--icf=all".
	append-flags -faddrsig
	append-flags -Wno-unknown-warning-option
	export CXXFLAGS_host+=" -Wno-unknown-warning-option"
	export CFLAGS_host+=" -Wno-unknown-warning-option"
	if use libcxx; then
		append-cxxflags "-stdlib=libc++"
		append-ldflags "-stdlib=libc++"
	fi

	# Workaround: Disable fatal linker warnings on arm64/lld.
	# https://crbug.com/913071
	# [mod] vtable_verify is disabled.
	use arm64 && append-ldflags "-Wl,--no-fatal-warnings"

	local flags
	einfo "Building with the compiler settings:"
	for flags in {C,CXX,CPP,LD}FLAGS; do
		einfo "  ${flags} = ${!flags}"
	done
}

src_configure() {
	tc-export CXX CC AR AS NM RANLIB STRIP
	export CC_host=$(tc-getBUILD_CC)
	export CXX_host=$(tc-getBUILD_CXX)
	export NM_host=$(tc-getBUILD_NM)
	export READELF="llvm-readelf"
	export READELF_host="llvm-readelf"

	# Use C++ compiler as the linker driver.
	export LD="${CXX}"
	export LD_host=${CXX_host}

	# We need below change when USE="thinlto" is set. We set this globally
	# so that users can turn on the "use_thin_lto" in the simplechrome
	# flow more easily.
	# use nm from llvm, https://crbug.com/917193
	export NM="llvm-nm"
	export NM_host="llvm-nm"
	export AR="llvm-ar"
	# USE=thinlto affects host build, we need to set host AR to
	# llvm-ar to make sure host package builds with thinlto.
	# crbug.com/731335
	export AR_host="llvm-ar"
	export RANLIB="llvm-ranlib"

	# Set binutils path for goma.
	CC_host+=" -B$(get_binutils_path "${LD_host}")"
	CXX_host+=" -B$(get_binutils_path "${LD_host}")"

	setup_compile_flags

	# We might set BOTO_CONFIG in the builder environment in case the
	# existing file needs modifications (e.g. for working with older
	# branches). So don't overwrite it if it's already set.
	# See https://crbug.com/847676 for details.
	export BOTO_CONFIG="${BOTO_CONFIG:-/home/$(whoami)/.boto}"
	export PATH=${PATH}:${DEPOT_TOOLS}

	export DEPOT_TOOLS_GSUTIL_BIN_DIR="${CHROME_CACHE_DIR}/gsutil_bin"

	# TODO(rcui): crosbug.com/20435. Investigate removal of runhooks
	# useflag when chrome build switches to Ninja inside the chroot.
	if use runhooks; then
		local cmd=( "${EGCLIENT}" runhooks --force )
		echo "${cmd[@]}"
		CFLAGS="${CFLAGS} ${EBUILD_CFLAGS[*]}" \
		CXXFLAGS="${CXXFLAGS} ${EBUILD_CXXFLAGS[*]}" \
		LDFLAGS="${LDFLAGS} ${EBUILD_LDFLAGS[*]}" \
		"${cmd[@]}" || die
	fi

	# [Mod] Unrelated V8 configurations are removed.
	BUILD_STRING_ARGS+=(
		"cros_target_ar=${AR}"
		"cros_target_cc=${CC}"
		"cros_target_cxx=${CXX}"
		"host_toolchain=//build/toolchain/cros:host"
		"custom_toolchain=//build/toolchain/cros:target"
		"cros_target_ld=${LD}"
		"cros_target_nm=${NM}"
		"cros_target_readelf=${READELF}"
		"cros_target_extra_cflags=${CFLAGS} ${EBUILD_CFLAGS[*]}"
		"cros_target_extra_cppflags=${CPPFLAGS}"
		"cros_target_extra_cxxflags=${CXXFLAGS} ${EBUILD_CXXFLAGS[*]}"
		"cros_target_extra_ldflags=${LDFLAGS} ${EBUILD_LDFLAGS[*]}"
		"cros_host_cc=${CC_host}"
		"cros_host_cxx=${CXX_host}"
		"cros_host_ar=${AR_host}"
		"cros_host_ld=${LD_host}"
		"cros_host_nm=${NM_host}"
		"cros_host_readelf=${READELF_host}"
		"cros_host_extra_cflags=${CFLAGS_host}"
		"cros_host_extra_cxxflags=${CXXFLAGS_host}"
		"cros_host_extra_cppflags=${CPPFLAGS_host}"
		"cros_host_extra_ldflags=${LDFLAGS_host}"
	)

	local arg
	for arg in "${BUILD_STRING_ARGS[@]}"; do
		BUILD_ARGS+=("${arg%%=*}=\"${arg#*=}\"")
	done
	export GN_ARGS="${BUILD_ARGS[*]}"
	einfo "GN_ARGS = ${GN_ARGS}"
	local gn=(
		"${CHROME_ROOT}/src/buildtools/linux64/gn" gen
		"${CHROME_ROOT}/src/${BUILD_OUT_SYM}/${BUILDTYPE}"
		--args="${GN_ARGS}" --root="${CHROME_ROOT}/src"
		--root-target="//third_party/icu"
	)
	echo "${gn[@]}"
	"${gn[@]}" || die

	# [Mod] setup_test_lists and clang_tidy are removed.
}

chrome_make() {
	local build_dir="${BUILD_OUT_SYM}/${BUILDTYPE}"

	# If ThinLTO is enabled, we may have a cache from a previous link. Due
	# to fears about lack of reproducibility, we don't allow cache reuse
	# across rebuilds. The cache is still useful for artifacts shared
	# between multiple links done by this build (e.g. tests).
	use thinlto && rm -rf "${build_dir}/thinlto-cache"

	local command=(
		"${ENINJA}"
		-j"$(makeopts_jobs)"
		-C "${build_dir}"
		$(usex verbose -v "")
		"$@"
	)

	PATH=${PATH}:${DEPOT_TOOLS} "${command[@]}"
	local ret=$?
	[[ "${ret}" -eq 0 ]] || die
}

# [Mod] src_compile() is simplied because 1) the case CHROME_LOCAL=LOCAL_BINARY
# is excluded. 2) we do not need nacl or tests.
src_compile() {
	cd "${CHROME_ROOT}"/src || die "Cannot chdir to ${CHROME_ROOT}/src"

	chrome_make "icu"
}

# [Mod] src_install() is greatly simplied and totally new.
src_install() {
	local build_dir="src/${BUILD_OUT_SYM}/${BUILDTYPE}"
	local icu_lib_dir="${build_dir}/obj/third_party/icu/"
	mv "${icu_lib_dir}/libicui18n.a" "${icu_lib_dir}/libicui18n${CHROME_ICU_POSTFIX}.a"
	mv "${icu_lib_dir}/libicuuc.a" "${icu_lib_dir}/libicuuc${CHROME_ICU_POSTFIX}.a"
	dolib.a "${icu_lib_dir}/libicui18n${CHROME_ICU_POSTFIX}.a"
	dolib.a "${icu_lib_dir}/libicuuc${CHROME_ICU_POSTFIX}.a"
	# Install to chrome folder to make chrome work.
	insinto "${CHROME_DIR}"
	doins "${build_dir}/icudtl.dat"
	doins "${build_dir}/icudtl.dat.hash"

	# Install icu header to /usr/include/icu${CHROME_ICU_POSTFIX}/.
	local icu_headers=(
		"common/unicode/appendable.h"
		"common/unicode/brkiter.h"
		"common/unicode/bytestream.h"
		"common/unicode/char16ptr.h"
		"common/unicode/chariter.h"
		"common/unicode/errorcode.h"
		"common/unicode/localpointer.h"
		"common/unicode/locid.h"
		"common/unicode/parseerr.h"
		"common/unicode/platform.h"
		"common/unicode/ptypes.h"
		"common/unicode/putil.h"
		"common/unicode/rep.h"
		"common/unicode/schriter.h"
		"common/unicode/std_string.h"
		"common/unicode/strenum.h"
		"common/unicode/stringoptions.h"
		"common/unicode/stringpiece.h"
		"common/unicode/ubrk.h"
		"common/unicode/uchar.h"
		"common/unicode/uchriter.h"
		"common/unicode/uclean.h"
		"common/unicode/ucnv.h"
		"common/unicode/ucnv_err.h"
		"common/unicode/uconfig.h"
		"common/unicode/ucpmap.h"
		"common/unicode/ucurr.h"
		"common/unicode/udata.h"
		"common/unicode/udisplaycontext.h"
		"common/unicode/uenum.h"
		"common/unicode/uloc.h"
		"common/unicode/umachine.h"
		"common/unicode/umisc.h"
		"common/unicode/unifilt.h"
		"common/unicode/unifunct.h"
		"common/unicode/unimatch.h"
		"common/unicode/uniset.h"
		"common/unicode/unistr.h"
		"common/unicode/uobject.h"
		"common/unicode/urename.h"
		"common/unicode/ures.h"
		"common/unicode/uscript.h"
		"common/unicode/uset.h"
		"common/unicode/utext.h"
		"common/unicode/utf.h"
		"common/unicode/utf16.h"
		"common/unicode/utf8.h"
		"common/unicode/utf_old.h"
		"common/unicode/utypes.h"
		"common/unicode/uvernum.h"
		"common/unicode/uversion.h"
		"i18n/unicode/calendar.h"
		"i18n/unicode/gregocal.h"
		"i18n/unicode/regex.h"
		"i18n/unicode/timezone.h"
		"i18n/unicode/ucal.h"
		"i18n/unicode/ucsdet.h"
		"i18n/unicode/ufieldpositer.h"
		"i18n/unicode/uformattable.h"
		"i18n/unicode/unum.h"
		"i18n/unicode/uregex.h"
	)
	local f
	for f in "${icu_headers[@]}"; do
		insinto "/usr/include/icu${CHROME_ICU_POSTFIX}/${f%/*}"
		doins "${CHROME_ROOT}/src/third_party/icu/source/${f}"
	done
}
