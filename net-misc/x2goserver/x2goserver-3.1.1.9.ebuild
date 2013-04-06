# Distributed under the terms of the GNU General Public License v2

EAPI=4
inherit eutils multilib toolchain-funcs user

DESCRIPTION="The X2Go server"
HOMEPAGE="http://www.x2go.org"
SRC_URI="http://code.x2go.org/releases/source/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+fuse postgres +sqlite"

REQUIRED_USE="|| ( postgres sqlite )"

DEPEND="sys-apps/man-db"

RDEPEND="dev-perl/Config-Simple
	media-fonts/font-cursor-misc
	media-fonts/font-misc-misc
	net-misc/nx
	virtual/ssh
	fuse? ( sys-fs/sshfs-fuse )
	postgres? ( dev-perl/DBD-Pg )
	sqlite? ( dev-perl/DBD-SQLite )"

pkg_setup() {
	enewuser x2gouser -1 -1 /var/lib/x2go
	enewuser x2goprint -1 -1 /var/spool/x2goprint
}

src_prepare() {
	# Respect CC/CFLAGS
	epatch "${FILESDIR}"/${PN}-3.1.1.4-cflags.patch

	# Remove man2html
	EPATCH_SOURCE="${FILESDIR}/patches-3.1.1.9" EPATCH_SUFFIX="patch" \
		EPATCH_FORCE="yes" epatch

	# Multilib clean
	sed -e "/^LIBDIR=/s/lib/$(get_libdir)/" -i */Makefile || die "multilib sed failed"
	# Use nxagent directly
	sed -i -e "s/x2goagent/nxagent/" x2goserver/bin/x2gostartagent || die "sed failed"
}

src_compile() {
	emake CC="$(tc-getCC)"
}

src_install() {
	emake DESTDIR="${D}" PREFIX=/usr install

	fowners root:x2goprint /usr/bin/x2goprint
	fperms 2755 /usr/bin/x2goprint
	dosym /usr/share/applications /etc/x2go/applications

	newinitd "${FILESDIR}"/${PN}.init x2gocleansessions
}

pkg_postinst() {
	if use sqlite ; then
		elog "To use sqlite and create the initial database, run:"
		elog " # x2godbadmin --createdb"
	fi
	if use postgres ; then
		elog "To use a PostgreSQL databse, more information is availabe here:"
		elog "http://www.x2go.org/doku.php/wiki:advanced:multi-node:x2goserver-pgsql"
	fi

	elog "For password authentication, you need to enable PasswordAuthentication"
	elog "in /etc/ssh/sshd_config (disabled by default in Gentoo)"
	elog "An init script was installed for x2gocleansessions"
}

