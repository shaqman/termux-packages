TERMUX_PKG_HOMEPAGE=https://rada.re
TERMUX_PKG_DESCRIPTION="Advanced Hexadecimal Editor"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_VERSION=3.9.0
TERMUX_PKG_SHA256=270cf67d0dee8dab4ed21dfaab57671b479ec82f0fc8d1c988e121c48b51addc
TERMUX_PKG_SRCURL=https://github.com/radare/radare2/archive/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_DEPENDS="libuv"
TERMUX_PKG_BREAKS="radare2-dev"
TERMUX_PKG_REPLACES="radare2-dev"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--with-compiler=termux-host"

termux_step_pre_configure() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	# Unset CPPFLAGS to avoid -I$TERMUX_PREFIX/include. This is because
	# radare2 build will put it's own -I flags after ours, which causes
	# problems due to name clashes (binutils header files).
	unset CPPFLAGS

	# If this variable is not set, then build will fail on linking with 'pthread'
	export ANDROID=1

	export OBJCOPY=$TERMUX_HOST_PLATFORM-objcopy

	# Remove old libs which may mess with new build:
	rm -f $TERMUX_PREFIX/lib/libr_*
}
