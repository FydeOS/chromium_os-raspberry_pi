# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_PROJECT="chromiumos/third_party/kernel"
CROS_WORKON_LOCALNAME="kernel/v6.12-rpi"
CROS_WORKON_EGIT_BRANCH="rpi-6.12.y"
CROS_WORKON_OUTOFTREE_BUILD=1

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="FydeOS Linux Kernel 6.12"
KEYWORDS="~*"

cros-kernel_apply_patches() {
  einfo "skip patches"
}
