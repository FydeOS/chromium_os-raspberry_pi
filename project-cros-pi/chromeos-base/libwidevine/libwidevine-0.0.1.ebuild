# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="Setup Widevine DRM"
HOMEPAGE="https://www.widevine.com/solutions/widevine-drm"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
    chromeos-base/chromeos-chrome
"

DEPEND="${RDEPEND}"

BUILDTYPE="${BUILDTYPE:-Release}"
BOARD="${BOARD:-${SYSROOT##/build/}}"
BUILD_OUT="${BUILD_OUT:-out_${BOARD}}"

CHROME_SRC=chrome-src
CHROME_CACHE_DIR=/var/cache/chromeos-chrome/${CHROME_SRC}
CHROME_DIR=/opt/google/chrome

S=${WORKDIR}

src_install() {
  FROM="${CHROME_CACHE_DIR}/src/${BUILD_OUT}/${BUILDTYPE}"    
  exeinto ${CHROME_DIR}
  doexe ${FROM}/libwidevinecdm.so
}
