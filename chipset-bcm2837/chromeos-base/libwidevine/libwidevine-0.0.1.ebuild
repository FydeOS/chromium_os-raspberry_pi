# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

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
