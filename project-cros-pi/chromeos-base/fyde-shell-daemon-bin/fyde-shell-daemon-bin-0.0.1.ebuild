# Copyright (c) 2020 The Fyde Innovations. All rights reserved.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="Setup shell daemon helper to allow certain privileged extension to execute shell commands"
HOMEPAGE="https://fydeos.io"

LICENSE="BSD"
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
