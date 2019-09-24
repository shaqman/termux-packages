TERMUX_PKG_HOMEPAGE=https://www.rust-lang.org/
TERMUX_PKG_DESCRIPTION="Systems programming language focused on safety, speed and concurrency"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="Kevin Cotugno @kcotugno"
TERMUX_PKG_VERSION=1.36.0
TERMUX_PKG_SRCURL=https://static.rust-lang.org/dist/rustc-$TERMUX_PKG_VERSION-src.tar.xz
TERMUX_PKG_SHA256=f51645b9f787af4a5d94db17f6af39db0c55980ed24fe366cad55b57900f8f2d
TERMUX_PKG_DEPENDS="libc++, clang, openssl, lld, zlib"

termux_step_configure() {
	termux_setup_cmake
	termux_setup_rust

	# it breaks building rust tools without doing this because it tries to find
	# ../lib from bin location:
	# this is about to get ugly but i have to make sure a rustc in a proper bin lib
	# configuration is used otherwise it fails a long time into the build...
	# like 30 to 40 + minutes ... so lets get it right

	# 1.36 needs 1.35 to build revert to using $TERMUX_PKG_VERSION next time..
	rustup install 1.35.0
	export PATH=$HOME/.rustup/toolchains/1.35.0-x86_64-unknown-linux-gnu/bin:$PATH
	local RUSTC=$(which rustc)
	local CARGO=$(which cargo)

	sed "s%\\@TERMUX_PREFIX\\@%$TERMUX_PREFIX%g" \
		$TERMUX_PKG_BUILDER_DIR/config.toml \
		| sed "s%\\@TERMUX_STANDALONE_TOOLCHAIN\\@%$TERMUX_STANDALONE_TOOLCHAIN%g" \
		| sed "s%\\@triple\\@%$CARGO_TARGET_NAME%g" \
		| sed "s%\\@RUSTC\\@%$RUSTC%g" \
		| sed "s%\\@CARGO\\@%$CARGO%g" \
		> config.toml

	local env_host=$(printf $CARGO_TARGET_NAME | tr a-z A-Z | sed s/-/_/g)
	export LD_LIBRARY_PATH=$TERMUX_PKG_BUILDDIR/build/x86_64-unknown-linux-gnu/stage2/lib
	export ${env_host}_OPENSSL_DIR=$TERMUX_PREFIX
	export X86_64_UNKNOWN_LINUX_GNU_OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
	export X86_64_UNKNOWN_LINUX_GNU_OPENSSL_INCLUDE_DIR=/usr/include
	export PKG_CONFIG_ALLOW_CROSS=1
	# for backtrace-sys
	export CC_x86_64_unknown_linux_gnu=gcc
	export CFLAGS_x86_64_unknown_linux_gnu="-O2"
	unset CC CXX CPP LD CFLAGS CXXFLAGS CPPFLAGS LDFLAGS PKG_CONFIG AR RANLIB
}

termux_step_make() {
return 0;
}

termux_step_make_install() {
	$TERMUX_PKG_SRCDIR/x.py install  \
		--host $CARGO_TARGET_NAME \
		--target $CARGO_TARGET_NAME \
		--target wasm32-unknown-unknown

	cd "$TERMUX_PREFIX/lib"
	ln -sf rustlib/$CARGO_TARGET_NAME/lib/*.so .
	ln -sf $TERMUX_PREFIX/bin/lld $TERMUX_PREFIX/bin/rust-lld
}
