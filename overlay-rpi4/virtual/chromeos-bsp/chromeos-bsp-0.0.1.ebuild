# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="4"

DESCRIPTION="vistual bsp"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  chromeos-base/baseboard-bsp
  virtual/fyde-packages
  virtual/cros-camera-hal
  virtual/cros-camera-hal-configs
  app-editors/nano
  chromeos-base/chromeos-bsp-rpi4"

DEPEND="${RDEPEND}"
