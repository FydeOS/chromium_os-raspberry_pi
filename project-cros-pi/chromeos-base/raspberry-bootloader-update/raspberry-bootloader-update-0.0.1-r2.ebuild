# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="7"

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
