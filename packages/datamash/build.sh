TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/datamash/
TERMUX_PKG_DESCRIPTION="GNU datamash performs basic numeric,textual and statistical operations"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_VERSION=1.5
TERMUX_PKG_SHA256=226249d5fe54024f96404798778f45963a3041714229d4225cd5d9acdaba21ad
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/gnu/datamash/datamash-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	if $TERMUX_DEBUG; then
		# When doing debug build, -D_FORTIFY_SOURCE=2 gives this error:
		# /home/builder/.termux-build/_cache/19b-aarch64-24-v5/bin/../sysroot/usr/include/bits/fortify/stdio.h:51:53: error: use of undeclared identifier '__USE_FORTIFY_LEVEL'
		# return __builtin___vsnprintf_chk(dest, size, 0, __bos(dest), format, ap);
		#                                                 ^
		# lib/cdefs.h:123:48: note: expanded from macro '__bos'
		# #define __bos(ptr) __builtin_object_size (ptr, __USE_FORTIFY_LEVEL > 1)
		#                                                ^
		export CFLAGS=${CFLAGS/-D_FORTIFY_SOURCE=2/}
	fi
}
