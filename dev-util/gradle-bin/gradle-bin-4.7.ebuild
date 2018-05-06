# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# NOTE: The comments in this file are for instruction and documentation.
# They're not meant to appear with your final, production ebuild.  Please
# remember to remove them before submitting or committing your ebuild.  That
# doesn't mean you can't add your own comments though.

# The EAPI variable tells the ebuild format in use.
# It is suggested that you use the latest EAPI approved by the Council.
# The PMS contains specifications for all EAPIs. Eclasses will test for this
# variable if they need to use features that are not universal in all EAPIs.
EAPI=6

# inherit lists eclasses to inherit functions from. For example, an ebuild
# that needs the eautoreconf function from autotools.eclass won't work
# without the following line:
inherit java-pkg-2
#
# eclasses tend to list descriptions of how to use their functions properly.
# take a look at /usr/portage/eclass/ for more examples.

# Short one-line description of this package.
DESCRIPTION="The Gradle Build Tool"

# Homepage, not used by Portage directly but handy for developer reference
HOMEPAGE="https://gradle.org"

# Point to any required sources; these will be automatically downloaded by
# Portage.
SRC_URI="https://services.gradle.org/distributions/gradle-${PV}-bin.zip"


LICENSE="Apache-2.0"

SLOT="4.7"

KEYWORDS="~amd64"

IUSE=""

RDEPEND=">=virtual/jre-1.5"

GRADLE="${PN}-${SLOT}"
GRADLE_SHARE="/usr/share/${GRADLE}"

java_prepare() {
	rm -v bin/*.bat || die
	chmod 644 lib/*.jar || die
}

src_install() {
	dodir "${GRADLE_SHARE}"

	cp -Rp bin init.d lib media "${ED}/${GRADLE_SHARE}" || die "failed to copy"

	java-pkg_regjar "${ED}/${GRADLE_SHARE}"/bin/*.jar
	java-pkg_regjar "${ED}/${GRADLE_SHARE}"/lib/*.jar

	dodoc NOTICE getting-started.html

	dodir /usr/bin/
	dosym "${GRADLE_SHARE}/bin/gradle" /usr/bin/gradle-${SLOT}
}
