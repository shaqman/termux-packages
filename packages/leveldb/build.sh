TERMUX_PKG_HOMEPAGE=https://github.com/google/leveldb
TERMUX_PKG_DESCRIPTION="Fast key-value storage library"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_VERSION=1.22
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://github.com/google/leveldb/archive/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=55423cac9e3306f4a9502c738a001e4a339d1a38ffbee7572d4a07d5d63949b2
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BREAKS="leveldb-dev"
TERMUX_PKG_REPLACES="leveldb-dev"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="-DBUILD_SHARED_LIBS=TRUE"
