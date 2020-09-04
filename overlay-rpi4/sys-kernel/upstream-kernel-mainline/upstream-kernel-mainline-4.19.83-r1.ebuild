# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="linux"
CROS_WORKON_REPO="https://github.com/raspberrypi"
CROS_WORKON_BLACKLIST="1"
#CROS_WORKON_EGIT_BRANCH="rpi-4.19.y"
CROS_WORKON_COMMIT="3c235dcfe80a7c7ba360219e4a3ecb256f294376"
# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel2

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Linux Kernel Upstream (mainline)"
KEYWORDS="*"

src_compile() {
  export LOADADDR="0x80080000"  
  cros-kernel2_src_compile 
}
