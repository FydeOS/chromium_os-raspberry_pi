# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

P=${P#"arc-"}
PN=${PN#"arc-"}
S="${WORKDIR}/${P}"

MULTILIB_COMPAT=( abi_arm_{32,64} )
inherit autotools multilib-minimal arc-build

DESCRIPTION="A ELF object file access library"
HOMEPAGE="http://www.mr511.de/software/"
SRC_URI="http://www.mr511.de/software/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="debug"

DEPEND="!dev-libs/arc-elfutils"
RDEPEND="${DEPEND}"

DOCS=( ChangeLog README )

PATCHES=(
	"${FILESDIR}/${P}-build.patch"
	"${FILESDIR}/${PN}-0.8.13-64bit.patch"
)

src_prepare() {
	eapply_user
	eautoreconf
}

src_configure() {
	arc-build-select-clang
	multilib-minimal_src_configure
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		--prefix="${ARC_PREFIX}/vendor" \
		--disable-nls \
		--disable-shared \
		$(use_enable debug)
}

multilib_src_install() {
	emake \
		prefix="${ED}${ARC_PREFIX}"/vendor \
		libdir="${ED}${ARC_PREFIX}"/vendor/$(get_libdir) \
		install \
		install-compat \
		-j1 || die
}
