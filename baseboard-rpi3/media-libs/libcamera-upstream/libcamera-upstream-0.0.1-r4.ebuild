# Copyright 2023 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="a2b740b749dd25db533593c2001a5070ebc6f7d5"
CROS_WORKON_TREE="14d7c74f831e2ccd3157da13cd60e0ccc86878ee"
CROS_WORKON_PROJECT="chromiumos/third_party/libcamera"
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_LOCALNAME="libcamera/upstream"

LIBCAMERA_PIPELINES="auto"

LIBCAMERA_DEPEND=""

inherit cros-camera cros-workon libcamera

DESCRIPTION="Camera support library for Linux"

KEYWORDS="*"
