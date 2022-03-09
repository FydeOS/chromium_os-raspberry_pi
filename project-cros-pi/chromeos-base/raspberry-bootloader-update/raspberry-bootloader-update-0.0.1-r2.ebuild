# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}
  sys-kernel/raspberry-kernel
  chromeos-base/rpi-boot-bin
  "

S=${WORKDIR}

src_install() {
  insinto /usr/share/raspberry-boot
  doins ${ROOT}/firmware/rpi/*[!b].{dat,bin,elf}
  doins ${ROOT}/usr/src/linux/arch/arm64/boot/dts/broadcom/*.dtb
  insinto /usr/share/raspberry-boot/overlays
  doins ${ROOT}/usr/src/linux/arch/arm64/boot/dts/overlays/*.dtbo
  
}
