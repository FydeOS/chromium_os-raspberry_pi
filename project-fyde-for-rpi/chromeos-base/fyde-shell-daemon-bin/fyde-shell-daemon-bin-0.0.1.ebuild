# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Helper for chrome to do some shell stuff"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

S=$WORKDIR

src_install() {
  insinto /etc/dbus-1/system.d
  doins ${FILESDIR}/io.fydeos.ShellDaemon.conf
  insinto /etc/init
  doins ${FILESDIR}/fydeos-shell-daemon.conf
  exeinto /usr/share/fydeos_shell
  doexe ${FILESDIR}/fydeos_shell/*
}
