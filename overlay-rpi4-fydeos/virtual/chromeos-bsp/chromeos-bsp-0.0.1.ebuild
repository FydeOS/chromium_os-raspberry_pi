# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="4"

DESCRIPTION="vistual bsp"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  chromeos-base/fydeos-console-issue
  chromeos-base/fydeos-default-apps
  net-misc/patch-tlsdate
  net-misc/fydeos-remote-help
  chromeos-base/fydeos-dev-remote-patch
  chromeos-base/fydeos-stateful-updater
  chromeos-base/license-utils
  chromeos-base/google-drive-fs
  chromeos-base/fydeos-opengapps-scripts
  chromeos-base/baseboard-bsp
  virtual/fyde-packages
  virtual/fydemina
  chromeos-base/chromeos-bsp-rpi4"

DEPEND="${RDEPEND}"
