# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="4"

DESCRIPTION="vistual bsp"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  chromeos-base/fydeos-console-issue
  chromeos-base/fydeos-default-apps
  chromeos-base/google-drive-fs
  net-misc/patch-tlsdate
  net-misc/fydeos-remote-help
  chromeos-base/fydeos-dev-remote-patch
  chromeos-base/fydeos-stateful-updater
  chromeos-base/license-utils
  chromeos-base/fydeos-opengapps-scripts
  chromeos-base/baseboard-bsp
  virtual/fyde-packages
  virtual/fydemina
  app-i18n/rime-server
  app-i18n/chromeos-pinyin
  chromeos-base/chromeos-bsp-rpi4-fydeos"

DEPEND="${RDEPEND}"
