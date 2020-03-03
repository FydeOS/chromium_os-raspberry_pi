# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
ECLASS_DEBUG_OUTPUT=on
CROS_WORKON_PROJECT="linux"
CROS_WORKON_REPO="https://github.com/raspberrypi"
CROS_WORKON_BLACKLIST="1"

#CROS_WORKON_COMMIT="6c5efcf09c40d37f72692fdbdf6d461abede20f1"
#CROS_WORKON_COMMIT="c8afb87670f39fd3217932896f31d20a85cffb8a"
CROS_WORKON_EGIT_BRANCH="rpi-5.4.y"
EGIT_MASTER="$CROS_WORKON_EGIT_BRANCH"
EGIT_OPTIONS="--depth=1"
EGIT_NONBARE=1
CROS_WORKON_COMMIT="$CROS_WORKON_EGIT_BRANCH"
CROS_WORKON_LOCALNAME="kernel/upstream-kernel-mainline"
CROS_WORKON_TREE="205e6d715c51018df7229453a2ce70c769180115"
# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel2

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Linux Kernel Upstream (mainline)"
KEYWORDS="*"

src_compile() {
  export LOADADDR="0x80080000"  
  cros-kernel2_src_compile 
}
