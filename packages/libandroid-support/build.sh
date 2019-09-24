TERMUX_PKG_HOMEPAGE=https://github.com/termux/libandroid-support
TERMUX_PKG_DESCRIPTION="Library extending the Android C library (Bionic) for additional multibyte, locale and math support"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_VERSION=25
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://github.com/termux/libandroid-support/archive/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=42e7b55c2e5fc91cc0447fa8bea432e7a75ec78b03469330668af17aea56f660
TERMUX_PKG_PRE_DEPENDS="dpkg (>= 1.19.4-3)"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_ESSENTIAL=true

termux_step_make() {
	local c_file

	mkdir objects
	for c_file in $(find src -type f -iname \*.c); do
		$CC $CPPFLAGS $CFLAGS -std=c99 -DNULL=0 -fPIC -Iinclude \
			-c $c_file -o ./objects/$(basename "$c_file").o
	done

	cd objects
	ar rcu ../libandroid-support.a *.o
	$CC $LDFLAGS -shared -o ../libandroid-support.so *.o
}

termux_step_make_install() {
	install -Dm600 libandroid-support.a $TERMUX_PREFIX/lib/libandroid-support.a
	install -Dm600 libandroid-support.so $TERMUX_PREFIX/lib/libandroid-support.so
}
