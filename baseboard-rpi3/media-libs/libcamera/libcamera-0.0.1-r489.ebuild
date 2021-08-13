# Copyright 2021 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CXXEXCEPTIONS_FLAGS="-fno-exceptions"
CROS_WORKON_COMMIT="e56f1f493560e0b641bbe36a528a13767817afed"
CROS_WORKON_TREE="c8e597e8dc3dc91766fd0b28b32b1588bab63173"
CROS_WORKON_PROJECT="chromiumos/third_party/libcamera"
CROS_WORKON_INCREMENTAL_BUILD="1"

inherit cros-workon meson

DESCRIPTION="Camera support library for Linux"
HOMEPAGE="https://www.libcamera.org"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="*"
IUSE="debug dev doc ipu3 rkisp1 test udev"

RDEPEND="
	chromeos-base/cros-camera-libs
	dev? ( dev-libs/libevent[threads] )
	dev-libs/libyaml
	media-libs/libjpeg-turbo
	media-libs/libexif
	>=net-libs/gnutls-3.3:=
	media-libs/libyuv
	udev? ( virtual/libudev )
"

DEPEND="
	${RDEPEND}
	dev-libs/openssl
	>=dev-python/pyyaml-3:=
"

src_configure() {
	local pipelines=(
		"uvcvideo"
    "raspberrypi"
		$(usev ipu3)
		$(usev rkisp1)
	)

	pipeline_list() {
		printf '%s,' "$@" | sed 's:,$::'
	}

	BUILD_DIR="$(cros-workon_get_build_dir)"

	local emesonargs=(
		$(meson_use test)
		$(meson_feature dev cam)
		$(meson_feature doc documentation)
		-Dandroid="enabled"
		-Dandroid_platform="cros"
		-Dpipelines="$(pipeline_list "${pipelines[@]}")"
		--buildtype "$(usex debug debug plain)"
		--sysconfdir /etc/camera
	)
  cros_enable_cxx_exceptions
	meson_src_configure
}

src_compile() {
	meson_src_compile
}

src_install() {
	meson_src_install

	dosym ../libcamera.so "/usr/$(get_libdir)/camera_hal/libcamera.so"

	dostrip -x "/usr/$(get_libdir)/libcamera/"
}
