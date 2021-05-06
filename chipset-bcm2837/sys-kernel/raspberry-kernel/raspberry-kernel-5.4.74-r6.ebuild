# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_REPO="https://github.com/FydeOS"
CROS_WORKON_COMMIT="b34d1a93fa11c28d324c4ed206be1a38187bd2f4"
CROS_WORKON_PROJECT="kernel-raspberry_pi"
CROS_WORKON_LOCALNAME="kernel/v5.4-rpi"
CROS_WORKON_EGIT_BRANCH="cros-5.4"
CROS_WORKON_INCREMENTAL_BUILD="1"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel2

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Chromium OS Linux kernel 5.4"
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
