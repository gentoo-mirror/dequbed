# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils java-utils-2 java-pkg-2 java-ant-2 vim-plugin git-r3

DESCRIPTION="The power of Eclipse in your favorite editor."
HOMEPAGE="http://eclim.org/"
EGIT_REPO_URI="git://github.com/ervandew/eclim.git"

LICENSE="GPL-3"

SLOT="0"

KEYWORDS="~amd64"

IUSE="cdt +java doc +nvim vim"

COMMON_DEPEND=">=dev-util/eclipse-sdk-bin-4.5"
DEPEND="${COMMON_DEPEND}
		>=virtual/jdk-1.5
		doc? ( dev-python/sphinx )"

RDEPEND="${COMMON_DEPEND}
		vim? ( || ( app-editors/vim app-editors/gvim ) )
		nvim? ( app-editors/neovim )
		>=virtual/jre-1.5
		dev-java/nailgun"

vim_home="/usr/share/vim/vimfiles"
nvim_home="/usr/share/nvim/runtime"

pkg_setup() {
	best_eclipse="$(best_version dev-util/eclipse-sdk-bin)"
	eclipse_home="opt/${best_eclipse}"

	ewarn "Eclim can only use Eclipse plugins that have been installed globally!"
	ewarn "Please make sure that the plugins you need are installed in ${eclipse_home}."

	if use java; then
		mypkg_plugins="jdt,ant,maven,gradle"
	fi
	if use cdt; then
		mypkg_plugins="${mypkg_plugins},cdt"
	fi

	# Remove leading comma
	mypkg_plugins=${mypkg_plugins#,}
}

src_compile() {
	if use doc; then
		eant -Declipse.home="${ROOT}/${eclipse_home}" \
			 -Declipse.local="${T}" \
			 docs vimdocs
	fi

	mkdir -p "${T}/${eclipse_home}"
	mkdir -p "${T}/${vim_home}"
	if use vim; then
		eant -Declipse.home="${ROOT}/${eclipse_home}" \
			 -Dvim.files="${T}/${vim_home}" \
			 -Dplugins="${mypkg_plugins}" \
			 deploy
	fi
	if use nvim; then
		eant -Declipse.home="${ROOT}/${eclipse_home}" \
			 -Dvim.files="${T}/${nvim_home}" \
			 -Dplugins="${mypkg_plugins}" \
			 deploy
	fi
}

src_install() {
	if use vim; then
		dodir "${vim_home}"
		cp -a "${T}/${vim_home}/." "${D}/${vim_home}"
	fi
	if use nvim; then
		dodir "${nvim_home}"
		cp -a "${T}/${nvim_home}/." "${D}/${nvim_home}"
	fi
	dodir "${eclipse_home}"
	cp -a "${T}/${eclipse_home}/." "${D}/${eclipse_home}"
}
