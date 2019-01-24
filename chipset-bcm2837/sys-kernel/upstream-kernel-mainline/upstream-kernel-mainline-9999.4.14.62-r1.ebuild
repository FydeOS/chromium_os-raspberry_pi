# Copyright 2018 The FydeOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="linux"
CROS_WORKON_REPO="https://github.com/raspberrypi"
CROS_WORKON_EGIT_BRANCH="rpi-4.14.y"
CROS_WORKON_BLACKLIST="1"
CROS_WORKON_COMMIT="3acfcdec59180815f1341a4cff63eadb6d1da654"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit git-2 cros-kernel2 cros-workon

HOMEPAGE="https://www.raspberrypi.org/forum"
DESCRIPTION="Kernel source tree for Raspberry Pi Foundation-provided kernel builds"
KEYWORDS="arm arm64"

