# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_REPO="https://github.com/raspberrypi"
CROS_WORKON_COMMIT="14b35093ca68bf2c81bbc90aace5007142b40b40"
CROS_WORKON_PROJECT="linux"
CROS_WORKON_LOCALNAME="kernel/v5.10-rpi"
CROS_WORKON_EGIT_BRANCH="rpi-5.15.y"
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_MANUAL_UPREV=1
#ECLASS_DEBUG_OUTPUT="on"
EGIT_MASTER="rpi-5.15.y"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel2

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Chromium OS Linux kernel 5.15"
KEYWORDS="*"

# Change the following (commented out) number to the next prime number
# when you change "cros-kernel2.eclass" to work around http://crbug.com/220902
#
# NOTE: There's nothing magic keeping this number prime but you just need to
# make _any_ change to this file.  ...so why not keep it prime?
#
# Don't forget to update the comment in _all_ chromeos-kernel-x_x-9999.ebuild
# files (!!!)
#
# The coolest prime number is: 149
