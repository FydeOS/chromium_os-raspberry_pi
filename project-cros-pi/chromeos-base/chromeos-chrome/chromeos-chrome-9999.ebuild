# Copyright 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

# Usage: by default, downloads chromium browser from the build server.
# If CHROME_ORIGIN is set to one of {SERVER_SOURCE, LOCAL_SOURCE, LOCAL_BINARY},
# the build comes from the chromimum source repository (gclient sync),
# build server, locally provided source, or locally provided binary.
# If you are using SERVER_SOURCE, a gclient template file that is in the files
# directory which will be copied automatically during the build and used as
# the .gclient for 'gclient sync'.
# If building from LOCAL_SOURCE or LOCAL_BINARY specifying BUILDTYPE
# will allow you to specify "Debug" or another build type; "Release" is
# the default.

EAPI=7

# TODO(crbug.com/984182): We force Python 2 because depot_tools doesn't support Python 3.
PYTHON_COMPAT=( python2_7 )
inherit autotest-deponly binutils-funcs chromium-source cros-credentials cros-constants cros-sanitizers eutils flag-o-matic git-2 multilib toolchain-funcs user python-any-r1 multiprocessing

DESCRIPTION="Open-source version of Google Chrome web browser"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google chrome_internal? ( Google-TOS )"
SLOT="0"
KEYWORDS="~*"
IUSE="
	+afdo_use
	afdo_verify
	+accessibility
	app_shell
	asan
	+authpolicy
	+build_tests
	cdm_factory_daemon
	+chrome_debug
	+cfi
	cfm
	chrome_debug_tests
	chrome_dcheck
	chrome_internal
	chrome_media
	+chrome_remoting
	clang_tidy
	component_build
	cros-debug
	debug_fission
	+dwarf5
	+fonts
	goma
	goma_thinlto
	+highdpi
	iioservice
	intel_oemcrypto
	internal_gles_conform
	+libcxx
	libinput
	mojo
	msan
	+nacl
	neon
	+oobe_config
	opengl
	opengles
	orderfile_generate
	+orderfile_use
	orderfile_verify
	+runhooks
	strict_toolchain_checks
	+thinlto
	touchview
	ubsan
	v4l2_codec
	v4lplugin
	vaapi
	verbose
	vtable_verify
	xkbcommon
	"
REQUIRED_USE="
	cfi? ( thinlto )
	afdo_verify? ( !afdo_use )
	orderfile_generate? ( !orderfile_use )
	"

OZONE_PLATFORM_PREFIX=ozone_platform_
OZONE_PLATFORMS=(gbm cast headless egltest caca)
IUSE_OZONE_PLATFORMS="${OZONE_PLATFORMS[@]/#/${OZONE_PLATFORM_PREFIX}}"
IUSE+=" ${IUSE_OZONE_PLATFORMS}"
OZONE_PLATFORM_DEFAULT_PREFIX=ozone_platform_default_
IUSE_OZONE_PLATFORM_DEFAULTS="${OZONE_PLATFORMS[@]/#/${OZONE_PLATFORM_DEFAULT_PREFIX}}"
IUSE+=" ${IUSE_OZONE_PLATFORM_DEFAULTS}"
REQUIRED_USE+=" ^^ ( ${IUSE_OZONE_PLATFORM_DEFAULTS} )"

# The gclient hooks that run in src_prepare hit the network.
# https://crbug.com/731905
RESTRICT="network-sandbox mirror"

# Do not strip the nacl_helper_bootstrap binary because the binutils
# objcopy/strip mangles the ELF program headers.
# TODO(mcgrathr,vapier): This should be removed after portage's prepstrip
# script is changed to use eu-strip instead of objcopy and strip.
STRIP_MASK+=" */nacl_helper_bootstrap"

# Portage version without optional portage suffix.
CHROME_VERSION="${PV/_*/}"

# chrome destination directory
CHROME_DIR=/opt/google/chrome
D_CHROME_DIR="${D}/${CHROME_DIR}"

# For compilation/local chrome
BUILDTYPE="${BUILDTYPE:-Release}"
BOARD="${BOARD:-${SYSROOT##/build/}}"
BUILD_OUT="${BUILD_OUT:-out_${BOARD}}"
# WARNING: We are using a symlink now for the build directory to work around
# command line length limits. This will cause problems if you are doing
# parallel builds of different boards/variants.
# Unsetting BUILD_OUT_SYM will revert this behavior
BUILD_OUT_SYM="c"

UNVETTED_ORDERFILE_LOCATION=${AFDO_GS_DIRECTORY:-"gs://chromeos-toolchain-artifacts/orderfile/unvetted"}

# The following entry will be modified automatically for verifying orderfile or AFDO profile.
UNVETTED_ORDERFILE=""
UNVETTED_AFDO_FILE=""

add_orderfiles() {
	# For verify orderfile, only for a toolchain special build.
	if [[ -n ${UNVETTED_ORDERFILE} ]]; then
		SRC_URI+=" orderfile_verify? ( ${UNVETTED_ORDERFILE_LOCATION}/${UNVETTED_ORDERFILE}.xz )"
	fi
}

add_orderfiles

RDEPEND="${RDEPEND}
	app-arch/bzip2
	app-crypt/mit-krb5
	app-misc/edid-decode
	authpolicy? ( chromeos-base/authpolicy )
	~chromeos-base/chrome-icu-${PV}
	chromeos-base/gestures
	chromeos-base/libevdev:=
	fonts? ( chromeos-base/chromeos-fonts )
	chrome_internal? ( chromeos-base/quickoffice )
	dev-libs/nspr
	>=dev-libs/nss-3.12.2
	libinput? ( dev-libs/libinput:= )
	>=media-libs/alsa-lib-1.0.19
	media-libs/fontconfig
	media-libs/libsync
	x11-libs/libdrm
	ozone_platform_gbm? ( media-libs/minigbm )
	v4lplugin? ( media-libs/libv4lplugins )
	>=media-sound/adhd-0.0.1-r310
	net-print/cups
	opengl? ( virtual/opengl )
	opengles? ( virtual/opengles )
	sys-apps/dbus
	sys-apps/pciutils
	virtual/udev
	sys-libs/libcap
	chrome_remoting? ( sys-libs/pam )
	vaapi? ( x11-libs/libva )
	xkbcommon? (
		x11-libs/libxkbcommon
		x11-misc/xkeyboard-config
	)
	accessibility? (
		app-accessibility/brltty
		app-accessibility/espeak-ng
		app-accessibility/googletts
	)
	libcxx? (
		sys-libs/libcxxabi
		sys-libs/libcxx
	)
	oobe_config? ( chromeos-base/oobe_config )
	iioservice? ( chromeos-base/iioservice )
	"

DEPEND="${DEPEND}
	${RDEPEND}
	chromeos-base/protofiles
	>=dev-util/gperf-3.0.3
	>=dev-util/pkgconfig-0.23
	arm? ( x11-libs/libdrm )
"

PATCHES=()

AUTOTEST_COMMON="src/chrome/test/chromeos/autotest/files"
AUTOTEST_DEPS="${AUTOTEST_COMMON}/client/deps"
AUTOTEST_DEPS_LIST="chrome_test telemetry_dep"

IUSE="${IUSE} +autotest"


QA_TEXTRELS="*"
QA_EXECSTACK="*"
QA_PRESTRIPPED="*"

use_nacl() {
	# 32bit asan conflicts with nacl: crosbug.com/38980
	! (use asan && [[ ${ARCH} == "x86" ]]) && \
	! use component_build && use nacl
}

# Like the `usex` helper:
# Usage: echox [int] [echo-if-true] [echo-if-false]
# If [int] is 0, then echo the 2nd arg (default of yes), else
# echo the 3rd arg (default of no).
echox() {
	# Like the `usex` helper.
	[[ ${1:-$?} -eq 0 ]] && echo "${2:-yes}" || echo "${3:-no}"
}
echotf() { echox ${1:-$?} true false ; }
usetf()  { usex $1 true false ; }

use_goma() {
	[[ "${USE_GOMA:-$(usetf goma)}" == "true" ]]
}
should_upload_build_logs() {
	[[ -n "${GOMA_TMP_DIR}" && -n "${GLOG_log_dir}" && \
		"${GLOG_log_dir}" == "${GOMA_TMP_DIR}"* ]]
}

set_build_args() {
	# use goma_thinlto says that if we are using Goma and ThinLTO, use
	# Goma for distributed code generation. So only set the corresponding
	# gn arg to true if all three conditions are met.
	use_goma_thin_lto=$(use goma_thinlto && use_goma && use thinlto; echotf)
	BUILD_ARGS=(
		"is_chromeos_device=true"
		# is_official_build sometimes implies extra optimizations (e.g. it will allow
		# ThinLTO to optimize more aggressively, if ThinLTO is enabled). Please note
		# that, despite the name, it should be usable by external users.
		#
		# Sanitizers don't like official builds.
		"is_official_build=$(use_sanitizers false true)"

		"is_debug=false"
		"${EXTRA_GN_ARGS}"
		"enable_pseudolocales=$(usetf cros-debug)"
		"use_chromeos_protected_av1=$(usetf intel_oemcrypto)"
		"use_chromeos_protected_media=$(usetf cdm_factory_daemon)"
		"use_iioservice=$(usetf iioservice)"
		"use_v4l2_codec=$(usetf v4l2_codec)"
		"use_v4lplugin=$(usetf v4lplugin)"
		"use_vaapi=$(usetf vaapi)"
		"use_xkbcommon=$(usetf xkbcommon)"
		"enable_remoting=$(usetf chrome_remoting)"
		"enable_nacl=$(use_nacl; echotf)"
		# use_system_minigbm is set below.

		"is_cfm=$(usetf cfm)"

		# Clang features.
		"is_asan=$(usetf asan)"
		"is_msan=$(usetf msan)"
		"is_ubsan=$(usetf ubsan)"
		"is_clang=true"
		"use_thin_lto=$(usetf thinlto)"
		"use_goma_thin_lto=${use_goma_thin_lto}"
		"is_cfi=$(usetf cfi)"
		"use_dwarf5=$(usetf dwarf5)"

		# Assistant integration tests are only run on the Chromium bots,
		# but they increase the size of libassistant.so by 1.3MB so we
		# disable them here.
		"enable_assistant_integration_tests=false"

		# Generate debug info necessary for AutoFDO.
		"clang_emit_debug_info_for_profiling=true"

		# Add libinput to handle touchpad.
		"use_libinput=$(usetf libinput)"
	)

	# BUILD_STRING_ARGS needs appropriate quoting. So, we keep them separate and
	# add them to BUILD_ARGS at the end.
	BUILD_STRING_ARGS=(
		"target_sysroot=${SYSROOT}"
		"system_libdir=$(get_libdir)"
		"pkg_config=$(tc-getPKG_CONFIG)"
		"target_os=chromeos"
		"host_pkg_config=$(tc-getBUILD_PKG_CONFIG)"
		"clang_diagnostic_dir=/tmp/clang_crash_diagnostics"
	)
	use internal_gles_conform && BUILD_ARGS+=( "internal_gles2_conform_tests=true" )

	# Ozone platforms.
	local platform
	for platform in ${OZONE_PLATFORMS[@]}; do
		local flag="${OZONE_PLATFORM_DEFAULT_PREFIX}${platform}"
		if use "${flag}"; then
			BUILD_STRING_ARGS+=( "ozone_platform=${platform}" )
		fi
	done
	BUILD_ARGS+=(
		"ozone_auto_platforms=false"
	)
	for platform in ${IUSE_OZONE_PLATFORMS}; do
		if use "${platform}"; then
			BUILD_ARGS+=( "${platform}=true" )
		fi
	done
	if use "ozone_platform_gbm"; then
		BUILD_ARGS+=( "use_system_minigbm=true" )
		BUILD_ARGS+=( "use_system_libdrm=true" )
	fi
	if use "touchview"; then
		BUILD_ARGS+=( "subpixel_font_rendering_disabled=true" )
	fi

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

	if use chrome_internal; then
		# Adding chrome branding specific variables.
		BUILD_ARGS+=( "is_chrome_branded=true" )
		# This test can only be build from internal sources.
		BUILD_ARGS+=( "internal_gles2_conform_tests=true" )
		export CHROMIUM_BUILD='_google_Chrome'
		export OFFICIAL_BUILD='1'
		export CHROME_BUILD_TYPE='_official'
	elif use chrome_media; then
		echo "Building Chromium with additional media codecs and containers."
		BUILD_ARGS+=( "proprietary_codecs=true" )
		BUILD_STRING_ARGS+=( "ffmpeg_branding=ChromeOS" )
	fi

	if use component_build; then
		BUILD_ARGS+=( "is_component_build=true" )
	fi
	if use_goma; then
		BUILD_ARGS+=( "use_goma=true" )
		BUILD_STRING_ARGS+=( "goma_dir=${GOMA_DIR:-/home/${WHOAMI}/goma}" )

		# Goma compiler proxy runs outside of portage build.
		# Practically, because TMPDIR is set in portage, it is
		# different from the directory used when the compiler proxy
		# started.
		# If GOMA_TMP_DIR is not set, the compiler proxy uses
		# TMPDIR/goma_${WHOAMI} for its tmpdir as fallback, which
		# causes unexpected behavior.
		# Specifically, named socket used to communicate with compiler
		# proxy is ${GOMA_TMP_DIR}/goma.ipc by default, so the compiler
		# proxy cannot be reached.
		# Thus, here set GOMA_TMP_DIR to /tmp/goma_${WHOAMI} if it is
		# not yet set.
		if [[ -z "${GOMA_TMP_DIR}" ]]; then
			export GOMA_TMP_DIR="/tmp/goma_${WHOAMI}"
		fi
	fi

	if use chrome_debug; then
		# Use debug fission to avoid 4GB limit of ELF32 (see crbug.com/595763).
		# Using -g1 causes problems with crash server (see crbug.com/601854).
		# Disable debug_fission for bots which generate AFDO profile. (see crbug.com/704602).
		local debug_level=2
		if use arm && ! use debug_fission; then
			# Limit debug info to -g1 to keep the binary size within 4GB.
			# Production builds do not use "-debug_fission". But it is used
			# by the AFDO builders and AFDO tools are fine with debug_level=1.
			debug_level=1
		fi
		BUILD_ARGS+=(
			"use_debug_fission=$(usetf debug_fission)"
			"symbol_level=${debug_level}"
		)
		if use debug_fission; then
			# The breakpad cannot handle the debug files generated by
			# llvm and debug fission properly. crosbug.com/710605
			append-flags -fno-split-dwarf-inlining
		fi
	fi

	# dcheck_always_on may default to true depending on the value of args
	# above, which we might not want. So let the chrome_dcheck USE flag
	# determine its value.
	BUILD_ARGS+=("dcheck_always_on=$(usetf chrome_dcheck)")
}

unpack_chrome() {
	# Add depot_tools to PATH, local chroot builds fail otherwise.
	export PATH=${PATH}:${DEPOT_TOOLS}

	local cmd=( "${CHROMITE_BIN_DIR}"/sync_chrome )
	use chrome_internal && cmd+=( --internal )
	if [[ "${CHROME_VERSION}" != "9999" ]]; then
		cmd+=( "--tag=${CHROME_VERSION}" )
	fi
	# --reset tells sync_chrome to blow away local changes and to feel
	# free to delete any directories that get in the way of syncing. This
	# is needed for unattended operation.
	cmd+=( --reset "--gclient=${EGCLIENT}" "${CHROME_DISTDIR}" )
	elog "${cmd[*]}"
	# TODO(crbug.com/1103048): Disable the sandbox when syncing the code.
	# It seems to break gclient execution at random for unknown reasons.
	# Children stop being tracked, or no git repos actually get cloned.
	SANDBOX_ON=0 "${cmd[@]}" || die
}

decide_chrome_origin() {
	if [[ "${PV}" == "9999" ]]; then
		# LOCAL_SOURCE is the default for cros_workon.
		# Warn the user if CHROME_ORIGIN is already set.
		if [[ -n "${CHROME_ORIGIN}" && "${CHROME_ORIGIN}" != LOCAL_SOURCE ]]; then
			ewarn "CHROME_ORIGIN is already set to ${CHROME_ORIGIN}."
			ewarn "This will prevent you from building from your local checkout."
			ewarn "Please run 'unset CHROME_ORIGIN' to reset Chrome"
			ewarn "to the default source location."
		fi
		: "${CHROME_ORIGIN:=LOCAL_SOURCE}"
	else
		# By default, pull from server.
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
	echo
	ewarn "If you want to develop or hack on the browser itself, you should follow the"
	ewarn "simple chrome workflow instead of using emerge:"
	ewarn "https://chromium.googlesource.com/chromiumos/docs/+/master/simple_chrome_workflow.md"
	echo

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

	cros-credentials_setup

	decide_chrome_origin

	case "${CHROME_ORIGIN}" in
	LOCAL_SOURCE|SERVER_SOURCE|LOCAL_BINARY)
		elog "CHROME_ORIGIN VALUE is ${CHROME_ORIGIN}"
		;;
	*)
		die "CHROME_ORIGIN not one of LOCAL_SOURCE, SERVER_SOURCE, LOCAL_BINARY"
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
		: ${CHROME_ROOT:=/home/${WHOAMI}/chrome_root}
		if [[ ! -d "${CHROME_ROOT}/src" ]]; then
			die "${CHROME_ROOT} does not contain a valid chromium checkout!"
		fi
		addwrite "${CHROME_ROOT}"
		;;
	esac

	case "${CHROME_ORIGIN}" in
	LOCAL_SOURCE|SERVER_SOURCE)
		set_build_args
		;;
	esac

	# FIXME: This is the normal path where ebuild stores its working data.
	# Chrome builds inside distfiles because of speed, so we at least make
	# a symlink here to add compatibility with autotest eclass which uses this.
	ln -sf "${CHROME_ROOT}" "${WORKDIR}/${P}"

	if use internal_gles_conform; then
		local CHROME_GLES2_CONFORM=${CHROME_ROOT}/src/third_party/gles2_conform
		local CROS_GLES2_CONFORM=/home/${WHOAMI}/trunk/src/third_party/gles2_conform
		if [[ ! -d "${CHROME_GLES2_CONFORM}" ]]; then
			if [[ -d "${CROS_GLES2_CONFORM}" ]]; then
				ln -s "${CROS_GLES2_CONFORM}" "${CHROME_GLES2_CONFORM}"
				einfo "Using GLES2 conformance test suite from ${CROS_GLES2_CONFORM}"
			else
				die "Trying to build GLES2 conformance test suite without ${CHROME_GLES2_CONFORM} or ${CROS_GLES2_CONFORM}"
			fi
		fi
	fi

	if use afdo_use; then
		# Use AFDO profile downloaded in Chromium source code
		# If needed profiles other than "silvermont", please set the variable
		# ${AFDO_PROFILE_SOURCE} accordingly.
		local afdo_src="${AFDO_PROFILE_SOURCE:-atom}"
		BUILD_ARGS+=( "clang_use_default_sample_profile=true" )
		BUILD_STRING_ARGS+=( "chromeos_afdo_platform=${afdo_src}" )
	fi

	# Use to verify a local unvetted AFDO file.
	if use afdo_verify; then
		if [[ ! -e "${UNVETTED_AFDO_FILE}" ]]; then
			die "Cannot find ${UNVETTED_AFDO_FILE} to build Chrome."
		fi
		BUILD_STRING_ARGS+=( "clang_sample_profile_path=${UNVETTED_AFDO_FILE}" )
	fi

	# Unpack unvetted orderfile.
	if use orderfile_verify; then
		local orderfile_dir="${WORKDIR}/orderfile"
		mkdir "${orderfile_dir}"
		local orderfile_file=${UNVETTED_ORDERFILE}
		(cd "${orderfile_dir}" && unpack "${orderfile_file}.xz") || die

		local orderfile_loc="${orderfile_dir}/${orderfile_file}"
		einfo "Using ${orderfile_loc} as orderfile for ordering Chrome"

		# Pass the path to orderfile to GN args.
		BUILD_STRING_ARGS+=( "chrome_orderfile_path=${orderfile_loc}" )
	fi

	if ! use orderfile_use; then
		# If not using orderfile, override the default orderfile path to empty.
		BUILD_STRING_ARGS+=( "chrome_orderfile_path=" )
	fi
}

add_api_keys() {
	# awk script to extract the values out of the file.
	local EXTRACT="{ gsub(/[',]/, \"\", \$2); print \$2 }"
	local api_key=$(awk "/google_api_key/ ${EXTRACT}" "$1")
	local client_id=$(awk "/google_default_client_id/ ${EXTRACT}" "$1")
	local client_secret=$(awk "/google_default_client_secret/ ${EXTRACT}" "$1")

	BUILD_STRING_ARGS+=(
		"google_api_key=${api_key}"
		"google_default_client_id=${client_id}"
		"google_default_client_secret=${client_secret}"
	)
}

src_prepare() {
	# Must call eapply_user in EAPI 7, but this function is a no-op here.
	eapply_user

	if [[ "${CHROME_ORIGIN}" != "LOCAL_SOURCE" &&
			"${CHROME_ORIGIN}" != "SERVER_SOURCE" ]]; then
		return
	fi

	elog "${CHROME_ROOT} should be set here properly"
	cd "${CHROME_ROOT}/src" || die "Cannot chdir to ${CHROME_ROOT}"

	# We do symlink creation here if appropriate.
	mkdir -p "${CHROME_CACHE_DIR}/src/${BUILD_OUT}"
	if [[ ! -z "${BUILD_OUT_SYM}" ]]; then
		rm -rf "${BUILD_OUT_SYM}" || die "Could not remove symlink"
		ln -sfT "${CHROME_CACHE_DIR}/src/${BUILD_OUT}" "${BUILD_OUT_SYM}" ||
			die "Could not create symlink for output directory"
	fi


	# Apply patches for non-localsource builds.
	if [[ "${CHROME_ORIGIN}" == "SERVER_SOURCE" && ${#PATCHES[@]} -gt 0 ]]; then
		eapply "${PATCHES[@]}"
	fi

	local WHOAMI=$(whoami)
	# Get the credentials to fake home directory so that the version of chromium
	# we build can access Google services. First, check for Chrome credentials.
	if [[ ! -d google_apis/internal ]]; then
		# Then look for Chrome OS supplied credentials.
		local PRIVATE_OVERLAYS_DIR=/home/${WHOAMI}/trunk/src/private-overlays
		local GAPI_CONFIG_FILE=${PRIVATE_OVERLAYS_DIR}/chromeos-overlay/googleapikeys
		if [[ ! -f "${GAPI_CONFIG_FILE}" ]]; then
			# Then developer credentials.
			GAPI_CONFIG_FILE=/home/${WHOAMI}/.googleapikeys
		fi
		if [[ -f "${GAPI_CONFIG_FILE}" ]]; then
			add_api_keys "${GAPI_CONFIG_FILE}"
		fi
	fi
}

setup_test_lists() {
	TEST_FILES=(
		capture_unittests
		dawn_end2end_tests
		dawn_unittests
		gl_tests
		jpeg_decode_accelerator_unittest
		ozone_gl_unittests
		sandbox_linux_unittests
		wayland_client_perftests
	)

	TEST_FILES+=( ppapi/examples/video_decode )

	if use vaapi || use v4l2_codec; then
		TEST_FILES+=(
			image_processor_test
			jpeg_encode_accelerator_unittest
			video_decode_accelerator_perf_tests
			video_decode_accelerator_tests
			video_encode_accelerator_perf_tests
			video_encode_accelerator_tests
		)
	fi

	if use vaapi; then
		TEST_FILES+=(
			decode_test
			vaapi_unittest
		)
	fi

	# TODO(ihf): Figure out how to keep this in sync with telemetry.
	TOOLS_TELEMETRY_BIN=(
		bitmaptools
		clear_system_cache
		minidump_stackwalk
	)

	PPAPI_TEST_FILES=(
		lib{32,64}
		mock_nacl_gdb
		ppapi_nacl_tests_{newlib,glibc}.nmf
		ppapi_nacl_tests_{newlib,glibc}_{x32,x64,arm,arm64}.nexe
		test_case.html
		test_case.html.mock-http-headers
		test_page.css
		test_url_loader_data
	)
}

# Handle all CFLAGS/CXXFLAGS/etc... munging here.
setup_compile_flags() {
	# Chrome controls its own optimization settings, so this would be a nop
	# if we were to run it. Leave it here anyway as a grep-friendly marker.
	# cros_optimize_package_for_speed

	# The chrome makefiles specify -O and -g flags already, so remove the
	# portage flags.
	filter-flags -g "-O*"

	# Remove unsupported arm64 linker flag on arm32 builds.
	# https://crbug.com/889079
	use arm && filter-flags "-Wl,--fix-cortex-a53-843419"

	# There are some flags we want to only use in the ebuild.
	# The rest will be exported to the simple chrome workflow.
	EBUILD_CFLAGS=()
	EBUILD_CXXFLAGS=()
	EBUILD_LDFLAGS=()

	if use thinlto; then
		# if using thinlto, we need to pass the equivalent of
		# -fdebug-types-section to the backend, to prevent out-of-range
		# relocations (see
		# https://bugs.chromium.org/p/chromium/issues/detail?id=1032159).
		append-ldflags -Wl,-mllvm
		append-ldflags -Wl,-generate-type-units
	else
		# Non-ThinLTO builds with symbol_level=2 may have out-of-range
		# relocations, too: crbug.com/1050819.
		append-flags -fdebug-types-section
	fi

	if use orderfile_generate; then
		local chrome_outdir="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"
		BUILD_STRING_ARGS+=( "dump_call_chain_clustering_order=${chrome_outdir}/chrome.orderfile.txt" )
		# Enable call graph profile sort (C3) to generate orderfile.
		BUILD_ARGS+=( "enable_call_graph_profile_sort=true" )
	fi

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
	export LDFLAGS_host+=" --unwindlib=libgcc"
	if use libcxx; then
		append-cxxflags "-stdlib=libc++"
		append-ldflags "-stdlib=libc++"
	fi

	# Workaround: Disable fatal linker warnings on arm64/lld.
	# https://crbug.com/913071
	use arm64 && append-ldflags "-Wl,--no-fatal-warnings"
	# Workaround: Disable fatal linker warnings on arm/lld.
	# https://crbug.com/1190544
	use arm && append-ldflags "-Wl,--no-fatal-warnings"
	use vtable_verify && append-ldflags -fvtable-verify=preinit

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
	# Use llvm's objcopy instead of GNU
	export OBJCOPY="llvm-objcopy"

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
	# The venv logic seems to misbehave when cross-compiling.  Since our SDK
	# should include all the necessary modules, just disable it (for now).
	# https://crbug.com/808434
	export VPYTHON_BYPASS="manually managed python not supported by chrome operations"

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

	BUILD_STRING_ARGS+=(
		"cros_target_ar=${AR}"
		"cros_target_cc=${CC}"
		"cros_target_cxx=${CXX}"
		"host_toolchain=//build/toolchain/cros:host"
		"custom_toolchain=//build/toolchain/cros:target"
		"v8_snapshot_toolchain=//build/toolchain/cros:v8_snapshot"
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
		"cros_v8_snapshot_cc=${CC_host}"
		"cros_v8_snapshot_cxx=${CXX_host}"
		"cros_v8_snapshot_ar=${AR_host}"
		"cros_v8_snapshot_ld=${LD_host}"
		"cros_v8_snapshot_nm=${NM_host}"
		"cros_v8_snapshot_readelf=${READELF_host}"
		"cros_v8_snapshot_extra_cflags=${CFLAGS_host}"
		"cros_v8_snapshot_extra_cxxflags=${CXXFLAGS_host}"
		"cros_v8_snapshot_extra_cppflags=${CPPFLAGS_host}"
		"cros_v8_snapshot_extra_ldflags=${LDFLAGS_host}"
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
	)
	echo "${gn[@]}"
	"${gn[@]}" || die

	setup_test_lists

	if use clang_tidy; then
		export WITH_TIDY=1
	fi
}

chrome_make() {
	local build_dir="${BUILD_OUT_SYM}/${BUILDTYPE}"

	# If ThinLTO is enabled, we may have a cache from a previous link. Due
	# to fears about lack of reproducibility, we don't allow cache reuse
	# across rebuilds. The cache is still useful for artifacts shared
	# between multiple links done by this build (e.g. tests).
	use thinlto && rm -rf "${build_dir}/thinlto-cache"

	# If goma is enabled, increase the number of parallel run to
	# 10 * {number of processors}. Though, if it is too large the
	# performance gets slow down, so limit by 200 heuristically.
	if use_goma; then
		local num_parallel=$(($(nproc) * 10))
		local j_limit=200
		set -- -j $((num_parallel < j_limit ? num_parallel : j_limit)) "$@"
	fi
	local command=(
		"${ENINJA}"
		-j"$(makeopts_jobs)"
		-C "${build_dir}"
		$(usex verbose -v "")
		-d "keeprsp"
		"$@"
	)
	# If goma is used, log the command, cwd and env vars, which will be
	# uploaded to the logging server.
	if should_upload_build_logs; then
		env --null > "${GLOG_log_dir}/ninja_env"
		pwd > "${GLOG_log_dir}/ninja_cwd"
		echo "${command[@]}" > "${GLOG_log_dir}/ninja_command"
	fi
	PATH=${PATH}:${DEPOT_TOOLS} "${command[@]}"
	local ret=$?
	if should_upload_build_logs; then
		echo "${ret}" > "${GLOG_log_dir}/ninja_exit"
		cp -p "${BUILD_OUT_SYM}/${BUILDTYPE}/.ninja_log" "${GLOG_log_dir}/ninja_log"
	fi
	[[ "${ret}" -eq 0 ]] || die

	# Still use a script to check if the orderfile is used properly, i.e.
	# Builtin_ functions are placed between the markers, etc.
	if use strict_toolchain_checks && (use orderfile_use || use orderfile_verify); then
		"${FILESDIR}/check_orderfile.py" "${build_dir}/chrome" || die
	fi
}

src_compile() {
	if [[ "${CHROME_ORIGIN}" != "LOCAL_SOURCE" &&
			"${CHROME_ORIGIN}" != "SERVER_SOURCE" ]]; then
		return
	fi

	cd "${CHROME_ROOT}"/src || die "Cannot chdir to ${CHROME_ROOT}/src"

	local chrome_targets=( $(usex mojo "mojo_shell" "") )
	if use app_shell; then
		chrome_targets+=( app_shell )
	else
		chrome_targets+=( chrome )
	fi
	if use build_tests; then
		chrome_targets+=(
			"${TEST_FILES[@]}"
			"${TOOLS_TELEMETRY_BIN[@]}"
			chromedriver
		)
		if use chrome_internal; then
			chrome_targets+=( libassistant_debug.so )
		fi
	fi
	use_nacl && chrome_targets+=( nacl_helper_bootstrap nacl_helper )

	chrome_make "${chrome_targets[@]}"

	if use build_tests; then
		install_chrome_test_resources "${WORKDIR}/test_src"
		install_telemetry_dep_resources "${WORKDIR}/telemetry_src"

		# NOTE: Since chrome is built inside distfiles, we have to get
		# rid of the previous instance first.
		# We remove only what we will overwrite with the mv below.
		local deps="${WORKDIR}/${P}/${AUTOTEST_DEPS}"

		rm -rf "${deps}/chrome_test/test_src"
		mv "${WORKDIR}/test_src" "${deps}/chrome_test/"

		rm -rf "${deps}/telemetry_dep/test_src"
		mv "${WORKDIR}/telemetry_src" "${deps}/telemetry_dep/test_src"

		# The autotest eclass wants this for some reason.
		get_paths() { :; }

		# HACK: It would make more sense to call autotest_src_prepare in
		# src_prepare, but we need to call install_chrome_test_resources first.
		autotest-deponly_src_prepare

		# Remove .git dirs
		find "${AUTOTEST_WORKDIR}" -type d -name .git -prune -exec rm -rf {} +

		autotest_src_compile
	fi
}

install_test_resources() {
	# Install test resources from chrome source directory to destination.
	# We keep a cache of test resources inside the chroot to avoid copying
	# multiple times.
	local test_dir="${1}"
	einfo "install_test_resources to ${test_dir}"
	shift

	# To speed things up, we write the list of files to a temporary file so
	# we can use rsync with --files-from.
	local tmp_list_file="${T}/${test_dir##*/}.files"
	printf "%s\n" "$@" > "${tmp_list_file}"

	# Copy the specific files to the cache from the source directory.
	# Note: we need to specify -r when using --files-from and -a to get a
	# recursive copy.
	# TODO(ihf): Make failures here fatal.
	rsync -r -a --delete --exclude=.git --exclude="*.pyc" \
		--files-from="${tmp_list_file}" "${CHROME_ROOT}/src/" \
		"${CHROME_CACHE_DIR}/src/"

	# Create hard links in the destination based on the cache.
	# Note: we need to specify -r when using --files-from and -a to get a
	# recursive copy.
	# TODO(ihf): Make failures here fatal.
	rsync -r -a --link-dest="${CHROME_CACHE_DIR}/src" \
		--files-from="${tmp_list_file}" "${CHROME_CACHE_DIR}/src/" "${test_dir}/"
}

test_strip_install() {
	local from="${1}"
	local dest="${2}"
	shift 2
	mkdir -p "${dest}"
	local f
	for f in "$@"; do
		$(tc-getSTRIP) --strip-debug \
			"${from}"/${f} -o "${dest}/$(basename ${f})"
	done
}

install_chrome_test_resources() {
	# NOTE: This is a duplicate from src_install, because it's required here.
	local from="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"
	local test_dir="${1}"
	local dest="${test_dir}/out/Release"

	echo Copying Chrome tests into "${test_dir}"

	# Even if chrome_debug_tests is enabled, we don't need to include detailed
	# debug info for tests in the binary package, so save some time by stripping
	# everything but the symbol names. Developers who need more detailed debug
	# info on the tests can use the original unstripped tests from the ${from}
	# directory.
	TEST_INSTALL_TARGETS=(
		"${TEST_FILES[@]}"
		"libppapi_tests.so" )

	einfo "Installing test targets: ${TEST_INSTALL_TARGETS[@]}"
	test_strip_install "${from}" "${dest}" "${TEST_INSTALL_TARGETS[@]}"

	# Copy Chrome test data.
	mkdir -p "${dest}"/test_data
	# WARNING: Only copy subdirectories of |test_data|.
	# The full |test_data| directory is huge and kills our VMs.
	# Example:
	# cp -al "${from}"/test_data/<subdir> "${test_dir}"/out/Release/<subdir>

	for f in "${PPAPI_TEST_FILES[@]}"; do
		cp -al "${from}/${f}" "${dest}"
	done

	# Install Chrome test resources.
	# WARNING: Only install subdirectories of |chrome/test|.
	# The full |chrome/test| directory is huge and kills our VMs.
	install_test_resources "${test_dir}" \
		base/base_paths_posix.cc \
		chrome/test/data/chromeos \
		chrome/test/functional \
		chrome/third_party/mock4js/mock4js.js  \
		content/common/gpu/testdata \
		media/test/data \
		content/test/data \
		net/data/ssl/certificates \
		ppapi/tests/test_case.html \
		ppapi/tests/test_url_loader_data \
		third_party/bidichecker/bidichecker_packaged.js \
		third_party/accessibility-developer-tools/gen/axs_testing.js

	# Add the pdf test data if needed.
	if use chrome_internal; then
		install_test_resources "${test_dir}" pdf/test
	fi
	# Add the gles_conform test data if needed.
	if use chrome_internal || use internal_gles_conform; then
		install_test_resources "${test_dir}" gpu/gles2_conform_support/gles2_conform_test_expectations.txt
	fi

	cp -a "${CHROME_ROOT}"/"${AUTOTEST_DEPS}"/chrome_test/setup_test_links.sh \
		"${dest}"
}

install_telemetry_dep_resources() {
	local test_dir="${1}"

	TELEMETRY=${CHROME_ROOT}/src/third_party/catapult/telemetry
	if [[ -r "${TELEMETRY}" ]]; then
		echo "Copying Telemetry Framework into ${test_dir}"
		mkdir -p "${test_dir}"
		# We are going to call chromium code but can't trust that it is clean
		# of precompiled code. See crbug.com/590762.
		find "${TELEMETRY}" -name "*.pyc" -type f -delete
		# Get deps from Chrome.
		FIND_DEPS=${CHROME_ROOT}/src/tools/perf/find_dependencies
		PERF_DEPS=${CHROME_ROOT}/src/tools/perf/bootstrap_deps
		CROS_DEPS=${CHROME_ROOT}/src/tools/cros/bootstrap_deps
		# sed removes the leading path including src/ converting it to relative.
		# To avoid silent failures assert the success.
		DEPS_LIST=$(python ${FIND_DEPS} ${PERF_DEPS} ${CROS_DEPS} | \
			sed -e 's|^'${CHROME_ROOT}/src/'||'; assert)
		install_test_resources "${test_dir}" "${DEPS_LIST}"
		# For crosperf, which uses some tests only available on internal builds.
		if use chrome_internal; then
			install_test_resources "${test_dir}" \
				data/page_cycler/morejs \
				data/page_cycler/moz
		fi
	fi

	local from="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"
	local dest="${test_dir}/src/out/${BUILDTYPE}"
	einfo "Installing telemetry binaries: ${TOOLS_TELEMETRY_BIN[@]}"
	test_strip_install "${from}" "${dest}" "${TOOLS_TELEMETRY_BIN[@]}"

	# When copying only a portion of the Chrome source that telemetry needs,
	# some symlinks can end up broken. Thus clean these up before packaging.
	find -L "${test_dir}" -type l -delete
}

# Add any new artifacts generated by the Chrome build targets to deploy_chrome.py.
# We deal with miscellaneous artifacts here in the ebuild.
src_install() {
	FROM="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"

	# Override default strip flags and lose the '-R .comment'
	# in order to play nice with the crash server.
	if [[ -z "${KEEP_CHROME_DEBUG_SYMBOLS}" ]]; then
		if [[ "${STRIP}" == "llvm-strip" ]]; then
			export PORTAGE_STRIP_FLAGS="--strip-all-gnu"
		else
			export PORTAGE_STRIP_FLAGS=""
		fi
	else
		export PORTAGE_STRIP_FLAGS="--strip-debug"
	fi
	einfo "PORTAGE_STRIP_FLAGS=${PORTAGE_STRIP_FLAGS}"
	LS=$(ls -alhS ${FROM})
	einfo "CHROME_DIR after build\n${LS}"

	# Copy a D-Bus config file that includes other configs that are installed to
	# /opt/google/chrome/dbus by deploy_chrome.
	insinto /etc/dbus-1/system.d
	doins "${FILESDIR}"/chrome.conf

	# Copy Quickoffice resources for official build.
	# Quickoffice is not yet available for arm64, https://crbug.com/881489
	if use chrome_internal && [[ "${ARCH}" != "arm64" ]]; then
		local qo_install_root="/usr/share/chromeos-assets/quickoffice"
		insinto "${qo_install_root}"
		QUICKOFFICE="${CHROME_ROOT}"/src/chrome/browser/resources/chromeos/quickoffice
		doins -r "${QUICKOFFICE}"/_locales
		doins -r "${QUICKOFFICE}"/css
		doins -r "${QUICKOFFICE}"/img
		doins -r "${QUICKOFFICE}"/plugin
		doins -r "${QUICKOFFICE}"/scripts
		doins -r "${QUICKOFFICE}"/views

		local qo_path=""
		case "${ARCH}" in
		arm)
			qo_path="${QUICKOFFICE}"/_platform_specific/arm
			;;
		amd64)
			qo_path="${QUICKOFFICE}"/_platform_specific/x86_64
			;;
		*)
			die "Unsupported architecture: ${ARCH}"
			;;
		esac

		# Compress the platform-specific NaCl binaries with squashfs to
		# save space on the rootfs.
		# - compress with LZO and 1M blocks to optimize trade-off
		# between compression ratio and decompression speed.
		# - use "-keep-as-directory" option so the squash file will
		# include the folder with the name of the CPU architecture,
		# which is expected by the scripts on device.
		# - use "-root-mode 0755" to ensure that the mountpoint has
		# permissions 0755 instead of the default 0777.
		# - use "-4k-align" option so individual files inside the squash
		# file will be aligned to 4K blocks, which improves the
		# efficiency of the delta updates.
		mksquashfs "${qo_path}" "${WORKDIR}/quickoffice.squash" \
			-all-root -noappend -no-recovery -no-exports \
			-exit-on-error -comp lzo -b 1M -keep-as-directory \
			-4k-align -root-mode 0755 -no-progress \
			|| die "Failed to create Quickoffice squashfs"

		# The squashfs will be mounted at boot time by an upstart script
		# installed by chromeos-base/quickoffice.
		doins "${WORKDIR}/quickoffice.squash"
	fi

	# Chrome test resources
	# Test binaries are only available when building chrome from source
	if use build_tests && [[ "${CHROME_ORIGIN}" == "LOCAL_SOURCE" ||
		"${CHROME_ORIGIN}" == "SERVER_SOURCE" ]]; then
		autotest-deponly_src_install
		#env -uRESTRICT prepstrip "${D}${AUTOTEST_BASE}"
	fi

	# Copy input_methods.txt for XkbToKcmConverter & auto-test.
	if [[ "${CHROME_ORIGIN}" == "LOCAL_SOURCE" ||
			"${CHROME_ORIGIN}" == "SERVER_SOURCE" ]]; then
		insinto /usr/share/chromeos-assets/input_methods
		sed -E -e '/^#/d' -e '/^$/d' -e 's:  +: :g' \
			"${CHROME_ROOT}"/src/chromeos/ime/input_methods.txt > "${T}/input_methods.txt" || die
		doins "${T}/input_methods.txt"
	fi

	# Fix some perms.
	# TODO(rcui): Remove this - shouldn't be needed, and is just covering up
	# potential permissions bugs.
	chmod -R a+r "${D}"
	find "${D}" -perm /111 -print0 | xargs -0 chmod a+x

	# The following symlinks are needed in order to run chrome.
	# TODO(rcui): Remove this.  Not needed for running Chrome.
	dosym libnss3.so /usr/lib/libnss3.so.1d
	dosym libnssutil3.so.12 /usr/lib/libnssutil3.so.1d
	dosym libsmime3.so.12 /usr/lib/libsmime3.so.1d
	dosym libssl3.so.12 /usr/lib/libssl3.so.1d
	dosym libplds4.so /usr/lib/libplds4.so.0d
	dosym libplc4.so /usr/lib/libplc4.so.0d
	dosym libnspr4.so /usr/lib/libnspr4.so.0d

	# Create the main Chrome install directory.
	dodir "${CHROME_DIR}"
	insinto "${CHROME_DIR}"

	# Install the orderfile into the chrome directory
	if use orderfile_generate; then
		[[ -f "${FROM}/chrome.orderfile.txt" ]] || die "No orderfile generated."
		doins "${FROM}/chrome.orderfile.txt"
	fi

	# Install the unvetted orderfile into the chrome directory for upload.
	if use orderfile_verify; then
		[[ -f "${DISTDIR}/${UNVETTED_ORDERFILE}.xz" ]] || die "Lost the unvetted orderfile."
		doins "${DISTDIR}/${UNVETTED_ORDERFILE}.xz"
	fi

	# Use the deploy_chrome from the *Chrome* checkout.  The benefit of
	# doing this is if a new buildspec of Chrome requires a non-backwards
	# compatible change to deploy_chrome, we can commit the fix to
	# deploy_chrome without breaking existing Chrome OS release builds,
	# and then roll the DEPS for chromite in the Chrome checkout.
	#
	# Another benefit is each version of Chrome will have the right
	# corresponding version of deploy_chrome.
	local cmd=( "${CHROME_ROOT}"/src/third_party/chromite/bin/deploy_chrome )
	# Disable stripping for now, as deploy_chrome doesn't generate splitdebug files.
	cmd+=(
		"--board=${BOARD}"
		"--build-dir=${FROM}"
		"--gn-args=${GN_ARGS}"
		# If this is enabled, we need to re-enable `prepstrip` above for autotests.
		# You'll also have to re-add "strip" to the RESTRICT at the top of the file.
		--nostrip
		"--staging-dir=${D_CHROME_DIR}"
		"--staging-flags=${USE}"
		--staging-only
		"--strip-bin=${STRIP}"
		"--strip-flags=${PORTAGE_STRIP_FLAGS}"
		--verbose
	)
	einfo "${cmd[*]}"
	"${cmd[@]}" || die
	LS=$(ls -alhS ${D}/${CHROME_DIR})
	einfo "CHROME_DIR after deploy_chrome\n${LS}"

	# Keep the .dwp files with debug fission.
	if use chrome_debug && use debug_fission; then
		mkdir -p "${D}/usr/lib/debug/${CHROME_DIR}"
		DWP="${CHOST}"-dwp
		cd "${D}/${CHROME_DIR}"
		# Iterate over all ELF files in current directory
		while read i; do
			cd "${FROM}"
			# These files do not build with -gsplit-dwarf,
			# so we do not need to get a .dwp file from them.
			if [[ "${i}" == "./libassistant.so"		|| \
				"${i}" == "./nacl_helper_nonsfi"	|| \
				"${i}" == "./nacl_helper_bootstrap"	|| \
				"${i}" == "./nacl_irt_arm.nexe"		|| \
				"${i}" == "./nacl_irt_x86_64.exe"	|| \
				"${i}" == "./nacl_irt_x86_64.nexe"	|| \
				"${i}" == "./libmojo_core_arc64.so"	|| \
				"${i}" == "./libmojo_core_arc32.so"	|| \
				"${i}" == "./libwidevinecdm.so" ]] ; then
				continue
			fi
			source="${i}"
			${DWP} -e "${FROM}/${source}" -o "${D}/usr/lib/debug/${CHROME_DIR}/${i}.dwp" || die
		done < <(scanelf -ByF '%F' ".")
	fi

	if use build_tests; then
		# Install Chrome Driver to test image.
		local chromedriver_dir='/usr/local/chromedriver'
		dodir "${chromedriver_dir}"
		cp -pPR "${FROM}"/chromedriver "${D}/${chromedriver_dir}" || die

		if use chrome_internal; then
			# Install LibAssistant test library to test image.
			into /usr/local/
			dolib.so "${FROM}"/libassistant_debug.so
		fi

		# Install a testing script to run Lacros from command line.
		into /usr/local
		dobin "${CHROME_ROOT}"/src/build/lacros/mojo_connection_lacros_launcher.py
	fi
	# The icu data is used by both chromeos-base/chrome-icu and this package.
	# chromeos-base/chrome-icu is responsible for installing the icu
	# data, so we remove it from ${D} here.
	rm "${D_CHROME_DIR}/icudtl.dat" || die
}

pkg_preinst() {
	enewuser "wayland"
	enewgroup "wayland"
	LS=$(ls -alhS ${ED}/${CHROME_DIR})
	einfo "CHROME_DIR after installation\n${LS}"
	CHROME_SIZE=$(stat --printf="%s" ${ED}/${CHROME_DIR}/chrome)
	einfo "CHROME_SIZE = ${CHROME_SIZE}"

	# Non-internal builds come with >10MB of unwinding info built-in. Size
	# checks on those are less profitable.
	if [[ ${CHROME_SIZE} -ge 250000000 && -z "${KEEP_CHROME_DEBUG_SYMBOLS}" ]] && use chrome_internal && ! use chrome_dcheck; then
		die "Installed chrome binary got suspiciously large (size=${CHROME_SIZE})."
	fi
	if use arm; then
		local files=$(find "${ED}/usr/lib/debug${CHROME_DIR}" -size +$((4 * 1024 * 1024 * 1024 - 1))c)
		[[ -n ${files} ]] && die "Debug files exceed 4GiB: ${files}"
	fi
	# Verify that the elf program headers in splitdebug binary match the chrome
	# binary, this is needed for correct symbolization in CWP.
	# b/128861198, https://crbug.com/1007548 .
	if [[ ${MERGE_TYPE} != binary ]] && use strict_toolchain_checks; then
		local chrome_headers=$(${READELF} --program-headers --wide \
			"${ED}/${CHROME_DIR}"/chrome | grep LOAD)
		local chrome_debug_headers=$(${READELF} --program-headers --wide \
			"${ED}/usr/lib/debug${CHROME_DIR}"/chrome.debug | grep LOAD)
		[[ "${chrome_headers}" != "${chrome_debug_headers}" ]] && \
			die "chrome program headers do not match chrome.debug"
	fi
}

pkg_postinst() {
	autotest_pkg_postinst
}
