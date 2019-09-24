TERMUX_PKG_HOMEPAGE=https://www.pango.org/
TERMUX_PKG_DESCRIPTION="Library for laying out and rendering text"
TERMUX_PKG_LICENSE="LGPL-2.0"
TERMUX_PKG_VERSION=1.44.6
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://ftp.gnome.org/pub/GNOME/sources/pango/${TERMUX_PKG_VERSION:0:4}/pango-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=3e1e41ba838737e200611ff001e3b304c2ca4cdbba63d200a20db0b0ddc0f86c
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="-Dintrospection=false"
TERMUX_PKG_DEPENDS="fontconfig, fribidi, glib, harfbuzz, libcairo, libffi"
TERMUX_PKG_BREAKS="pango-dev"
TERMUX_PKG_REPLACES="pango-dev"

termux_step_post_make_install() {
	install -Dm600 $TERMUX_PKG_BUILDER_DIR/pango-view.1 \
		$TERMUX_PREFIX/share/man/man1/pango-view.1
}
