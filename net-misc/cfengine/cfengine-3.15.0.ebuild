# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils autotools flag-o-matic

MY_PV="${PV//_beta/b}"
MY_PV="${MY_PV/_p/p}"
MY_P="${PN}-${MY_PV}"

DESCRIPTION="An automated suite of programs for configuring and maintaining computers"
HOMEPAGE="http://www.cfengine.org/"
SRC_URI="https://cfengine-package-repos.s3.amazonaws.com/tarballs/${MY_P}.tar.gz -> ${MY_P}.tar.gz
	masterfiles? ( https://cfengine-package-repos.s3.amazonaws.com/tarballs/${PN}-masterfiles-${MY_PV}.tar.gz -> ${PN}-masterfiles-${MY_PV}.tar.gz )"

LICENSE="GPL-3"
SLOT="3"
KEYWORDS="~amd64 ~x86"

IUSE="acl examples libvirt mysql masterfiles postgres +qdbm selinux tokyocabinet vim-syntax xml +yaml"

DEPEND="acl? ( virtual/acl )
	mysql? ( virtual/mysql )
	postgres? ( dev-db/postgresql:= )
	selinux? ( sys-libs/libselinux )
	tokyocabinet? ( dev-db/tokyocabinet )
	qdbm? ( dev-db/qdbm )
	libvirt? ( app-emulation/libvirt )
	xml? ( dev-libs/libxml2:2 )
	yaml? ( dev-libs/libyaml ) \
	dev-libs/openssl
	dev-libs/libpcre"
RDEPEND="${DEPEND}"
PDEPEND="vim-syntax? ( app-vim/cfengine-syntax )"

REQUIRED_USE="^^ ( qdbm tokyocabinet )"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	default
	#epatch "${FILESDIR}/${P}-ifconfig.patch"
	#epatch "${FILESDIR}/${P}-sysmacros.patch"
	eautoreconf
}

src_unpack() {
	unpack ${MY_P}.tar.gz
	if use masterfiles; then
		unpack ${PN}-masterfiles-${MY_PV}.tar.gz
	fi
}

src_configure() {
	# Enforce /var/cfengine for historical compatibility

	econf \
		--enable-fhs \
		--docdir=/usr/share/doc/${PF} \
		--with-workdir=/var/cfengine \
		--with-pcre \
		$(use_with acl libacl) \
		$(use_with qdbm) \
		$(use_with tokyocabinet) \
		$(use_with postgres postgresql) \
		$(use_with mysql mysql check) \
		$(use_with libvirt) \
		$(use_with yaml libyaml) \
		$(use_enable selinux)

	# Fix Makefile to skip inputs, see below "examples"
	#sed -i -e 's/\(SUBDIRS.*\) inputs/\1/' Makefile || die

	# We install the documentation through portage
	sed -i -e 's/\(install-data-am.*\) install-docDATA/\1/' Makefile || die
}

src_install() {
	newinitd "${FILESDIR}"/cf-serverd.rc6 cf-serverd || die
	newinitd "${FILESDIR}"/cf-monitord.rc6 cf-monitord || die
	newinitd "${FILESDIR}"/cf-execd.rc6 cf-execd || die

	emake DESTDIR="${D}" install || die

	# fix ifconfig path in provided promises
	find "${D}"/usr/share -name "*.cf" | xargs sed -i "s,/sbin/ifconfig,$(which ifconfig),g"

	# Evil workaround for now..
	mv "${D}"/usr/share/doc/${PN}/ "${D}"/usr/share/doc/${PF}

	dodoc AUTHORS

	if ! use examples; then
		rm -rf "${D}"/usr/share/doc/${PF}/example*
	fi

	# Create cfengine working directory
	dodir /var/cfengine/bin
	fperms 700 /var/cfengine

	# Copy cfagent into the cfengine tree otherwise cfexecd won't
	# find it. Most hosts cache their copy of the cfengine
	# binaries here. This is the default search location for the
	# binaries.
	# CFEngine binaries can be used by normal users as well, sym them into
	# /usr/bin instead
	for bin in promises agent monitord serverd execd runagent key; do
		dosym /usr/sbin/cf-$bin /var/cfengine/bin/cf-$bin || die
	done

	if use masterfiles; then
		insinto /var/cfengine
		doins -r "${WORKDIR}/masterfiles"
	fi

	for dir in inputs modules outputs plugins ppkeys state; do
		keepdir /var/cfengine/$dir
	done

	dodir /etc/env.d
	echo 'CONFIG_PROTECT=/var/cfengine/masterfiles' >"${ED}/etc/env.d/99${PN}" || die
}

pkg_postinst() {
	echo
	elog "NOTE: BDB (BerkelyDB) support has been removed as of ${PN}-3.3.0"
	echo
	einfo "Init scripts for cf-serverd, cf-monitord, and cf-execd are provided."
	einfo
	einfo "If you don't want to use the init scripts, you can run cfengine using cron:"
	einfo "0,30 * * * *    /usr/bin/cf-execd -O"
	echo

	elog "If you run cfengine the very first time, you MUST generate the keys for cfengine by running:"
	elog "emerge --config ${CATEGORY}/${PN}"

	# Fix old cf-servd, remove it after some releases.
	local found=0
	for fname in $(find /etc/runlevels/ -type f -or -type l -name 'cf-servd'); do
		found=1
		rm $fname
		ln -s /etc/init.d/cf-serverd $(echo $fname | sed 's:cf-servd:cf-serverd:')
	done

	if [ "${found}" -eq 1 ]; then
		echo
		elog "/etc/init.d/cf-servd has been renamed to /etc/init.d/cf-serverd"
	fi
}

pkg_config() {
	if [ "${ROOT}" == "/" ]; then
		if [ ! -f "/var/cfengine/ppkeys/localhost.priv" ]; then
			einfo "Generating keys for localhost."
			/usr/bin/cf-key
		fi
	else
		die "cfengine cfkey does not support any value of ROOT other than /."
	fi
}
