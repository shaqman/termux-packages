TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/gdb/
TERMUX_PKG_DESCRIPTION="The standard GNU Debugger that runs on many Unix-like systems and works for many programming languages"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_VERSION=8.3.1
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/gnu/gdb/gdb-${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=1e55b4d7cdca7b34be12f4ceae651623aa73b2fd640152313f9f66a7149757c4
TERMUX_PKG_DEPENDS="libc++, liblzma, libexpat, readline, ncurses, libmpfr, zlib"
TERMUX_PKG_BREAKS="gdb-dev"
TERMUX_PKG_REPLACES="gdb-dev"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--with-system-readline
--with-curses
ac_cv_func_getpwent=no
ac_cv_func_getpwnam=no
"
TERMUX_PKG_RM_AFTER_INSTALL="share/gdb/python share/gdb/syscalls share/gdb/system-gdbinit"
TERMUX_PKG_MAKE_INSTALL_TARGET="-C gdb install"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
	# Fix "undefined reference to 'rpl_gettimeofday'" when building:
	export gl_cv_func_gettimeofday_clobber=no
	export gl_cv_func_gettimeofday_posix_signature=yes
	export gl_cv_func_realpath_works=yes
	export gl_cv_func_lstat_dereferences_slashed_symlink=yes
	export gl_cv_func_memchr_works=yes
	export gl_cv_func_stat_file_slash=yes
	export gl_cv_func_frexp_no_libm=no
	export gl_cv_func_strerror_0_works=yes
	export gl_cv_func_working_strerror=yes
	export gl_cv_func_getcwd_path_max=yes
}
