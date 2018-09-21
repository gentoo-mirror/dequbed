# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils git-r3

DESCRIPTION="Simple screen locker"
HOMEPAGE="https://github.com/Arcaena/i3lock-color"
EGIT_REPO_URI="https://github.com/Arcaena/i3lock-color.git"
EGIT_BRANCH=master

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

MY_PN=i3lock

RDEPEND="!x11-misc/i3lock
	virtual/pam
	dev-libs/libev
	>=x11-libs/libxkbcommon-0.5.0[X]
	x11-libs/libxcb[xkb]
	x11-libs/xcb-util
	x11-libs/cairo[xcb]"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
DOCS=( CHANGELOG README.md )

pkg_setup() {
	tc-export CC
}

src_prepare() {
	epatch_user
	git tag -f "git-$(git rev-parse --short HEAD)"

	eautoreconf
}

src_install() {
	default
	doman ${MY_PN}.1
}
