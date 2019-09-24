LLVM_INSTALL_DIR=$TERMUX_PKG_BUILDDIR/llvm-install

TERMUX_PKG_HOMEPAGE=https://github.com/ldc-developers/ldc
TERMUX_PKG_DESCRIPTION="D programming language compiler, built with LLVM"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_VERSION=()
TERMUX_PKG_VERSION+=(1.17.0)
TERMUX_PKG_VERSION+=(8.0.1)   # LLVM version
TERMUX_PKG_VERSION+=(2.087.1) # TOOLS version
TERMUX_PKG_VERSION+=(1.16.0)  # DUB version
TERMUX_PKG_REVISION=4

TERMUX_PKG_SRCURL=(https://github.com/ldc-developers/ldc/releases/download/v${TERMUX_PKG_VERSION}/ldc-${TERMUX_PKG_VERSION}-src.tar.gz
		   https://github.com/ldc-developers/llvm/releases/download/ldc-v${TERMUX_PKG_VERSION[1]}/llvm-${TERMUX_PKG_VERSION[1]}.src.tar.xz
		   https://github.com/dlang/tools/archive/v${TERMUX_PKG_VERSION[2]}.tar.gz
		   https://github.com/dlang/dub/archive/v${TERMUX_PKG_VERSION[3]}.tar.gz
		   https://github.com/ldc-developers/ldc/releases/download/v${TERMUX_PKG_VERSION}/ldc2-${TERMUX_PKG_VERSION}-linux-x86_64.tar.xz)
TERMUX_PKG_SHA256=(6a2fa91a53d954361832591488241c92adb497842069077425d73c9b9d2c4fa9
		   af469483241e90366f910af32ca3a23e878ad8d2f29c0518811da19e1b6f4454
		   a7cb8b217f2841f1ebe513ac5090d6ef77e03dc72bf2047bf92632c263941810
		   f4291dc053864b81c10dc1e9f9220aee3d4ce7ef735ecdb70de9ecbf6e0aaa5b
		   715adbdd614edf926d5f53bb9f8bfa34d0c828aa40077cb627ce064955fd641d)
TERMUX_PKG_DEPENDS="clang, libc++, zlib"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_FORCE_CMAKE=true
#These CMake args are only used to configure a patched LLVM
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DLLVM_ENABLE_PIC=ON
-DLLVM_BUILD_TOOLS=OFF
-DLLVM_BUILD_UTILS=OFF
-DCOMPILER_RT_INCLUDE_TESTS=OFF
-DLLVM_ENABLE_TERMINFO=OFF
-DLLVM_ENABLE_LIBEDIT=OFF
-DLLVM_TABLEGEN=$TERMUX_PKG_HOSTBUILD_DIR/bin/llvm-tblgen
-DPYTHON_EXECUTABLE=$(which python3)
-DLLVM_TARGETS_TO_BUILD='AArch64;ARM;X86'
-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly
-DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL_DIR
"

termux_step_post_extract_package() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	mv llvm-${TERMUX_PKG_VERSION[1]}.src llvm
	mv tools-${TERMUX_PKG_VERSION[2]} dlang-tools
	mv dub-${TERMUX_PKG_VERSION[3]} dub

	export LLVM_TRIPLE=${TERMUX_HOST_PLATFORM/-/--}
	if [ $TERMUX_ARCH = arm ]; then LLVM_TRIPLE=${LLVM_TRIPLE/arm-/armv7a-}; fi
	sed $TERMUX_PKG_BUILDER_DIR/llvm-config.in \
		-e "s|@LLVM_VERSION@|${TERMUX_PKG_VERSION[1]}|g" \
		-e "s|@LLVM_INSTALL_DIR@|$LLVM_INSTALL_DIR|g" \
		-e "s|@TERMUX_PKG_SRCDIR@|$TERMUX_PKG_SRCDIR|g" \
		-e "s|@LLVM_DEFAULT_TARGET_TRIPLE@|$LLVM_TRIPLE|g" \
		-e "s|@LLVM_TARGETS@|AArch64 ARM X86 WebAssembly|g" > $TERMUX_PKG_BUILDDIR/llvm-config
	chmod 755 $TERMUX_PKG_BUILDDIR/llvm-config
}

termux_step_host_build() {
	termux_setup_cmake
	termux_setup_ninja

	# Build native llvm-tblgen, a prerequisite for cross-compiling LLVM
	cmake -GNinja $TERMUX_PKG_SRCDIR/llvm \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_BUILD_TOOLS=OFF \
		-DLLVM_BUILD_UTILS=OFF \
		-DCOMPILER_RT_INCLUDE_TESTS=OFF
	ninja -j $TERMUX_MAKE_PROCESSES llvm-tblgen
}

# Just before CMake invokation for LLVM:
termux_step_pre_configure() {
	LDFLAGS+=" -lc++_shared"

	local LLVM_TARGET_ARCH
	if [ $TERMUX_ARCH = "arm" ]; then
		LLVM_TARGET_ARCH=ARM
	elif [ $TERMUX_ARCH = "aarch64" ]; then
		LLVM_TARGET_ARCH=AArch64
		# LLVM 8.0.1's libclang_rt.hwasan-*-android.so fails to link for AArch64 and x86_64
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DCOMPILER_RT_BUILD_SANITIZERS=OFF"
	elif [ $TERMUX_ARCH = "i686" ]; then
		LLVM_TARGET_ARCH=X86
	elif [ $TERMUX_ARCH = "x86_64" ]; then
		LLVM_TARGET_ARCH=X86
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DCOMPILER_RT_BUILD_SANITIZERS=OFF"
	else
		termux_error_exit "Invalid arch: $TERMUX_ARCH"
	fi
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DLLVM_DEFAULT_TARGET_TRIPLE=${LLVM_TRIPLE}"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DLLVM_TARGET_ARCH=${LLVM_TARGET_ARCH}"

	# CPPFLAGS adds the system llvm to the include path, which causes
	# conflicts with the local patched llvm when compiling ldc
	CPPFLAGS=""

	OLD_TERMUX_PKG_SRCDIR=$TERMUX_PKG_SRCDIR
	TERMUX_PKG_SRCDIR=$TERMUX_PKG_SRCDIR/llvm

	OLD_TERMUX_PKG_BUILDDIR=$TERMUX_PKG_BUILDDIR
	TERMUX_PKG_BUILDDIR=$TERMUX_PKG_BUILDDIR/llvm
	mkdir "$TERMUX_PKG_BUILDDIR"
}

# CMake for LLVM has been run:
termux_step_post_configure() {
	# Cross-compile & install LLVM
	cd "$TERMUX_PKG_BUILDDIR"
	if test -f build.ninja; then
		ninja -j $TERMUX_MAKE_PROCESSES install
	fi

	# Replace non-native llvm-config executable with bash script,
	# as it is going to be invoked during LDC CMake config.
	mv ../llvm-config $LLVM_INSTALL_DIR/bin

	# Invoke CMake for LDC:

	TERMUX_PKG_SRCDIR=$OLD_TERMUX_PKG_SRCDIR
	TERMUX_PKG_BUILDDIR=$OLD_TERMUX_PKG_BUILDDIR
	cd "$TERMUX_PKG_BUILDDIR"

	export LDC_FLAGS="-mtriple=$LLVM_TRIPLE"
	if [ $TERMUX_ARCH = arm ]; then LDC_FLAGS="$LDC_FLAGS;-mcpu=cortex-a8"; fi

	export LDC_PATH=$TERMUX_PKG_SRCDIR/ldc2-$TERMUX_PKG_VERSION-linux-x86_64

	TERMUX_PKG_EXTRA_CONFIGURE_ARGS=" -DLLVM_ROOT_DIR=$LLVM_INSTALL_DIR \
		-DD_COMPILER=$LDC_PATH/bin/ldmd2 \
		-DCMAKE_INSTALL_PREFIX=$TERMUX_PREFIX"

	termux_step_configure_cmake
}

termux_step_make() {
	# Cross-compile the runtime libraries
	$LDC_PATH/bin/ldc-build-runtime --ninja -j $TERMUX_MAKE_PROCESSES \
		--dFlags="$LDC_FLAGS" --cFlags="$CFLAGS -I$TERMUX_PREFIX/include" \
		--targetSystem="Android;Linux;UNIX" --ldcSrcDir="$TERMUX_PKG_SRCDIR"

	# Set up ldmd2 for cross-compilation
	export DFLAGS="${LDC_FLAGS//;/ }"

	# Cross-compile LDC executables (linked against runtime libs above)
	if test -f build.ninja; then
		ninja -j $TERMUX_MAKE_PROCESSES ldc2 ldmd2 ldc-build-runtime
	fi

	# Cross-compile dlang tools and dub:

	DMD=$LDC_PATH/bin/ldmd2
	D_LDFLAGS="-fuse-ld=bfd -L$TERMUX_PKG_BUILDDIR/ldc-build-runtime.tmp/lib -lphobos2-ldc -ldruntime-ldc -Wl,--gc-sections -ldl -lm -fPIE -pie -Wl,-z,nocopyreloc ${LDFLAGS}"
	if [ $TERMUX_ARCH = arm ]; then D_LDFLAGS="$D_LDFLAGS -Wl,--fix-cortex-a8"; fi

	cd  $TERMUX_PKG_SRCDIR/dlang-tools
	$DMD -w -de -c rdmd.d -of=$TERMUX_PKG_BUILDDIR/bin/rdmd.o
	$DMD -w -de -c ddemangle.d -of=$TERMUX_PKG_BUILDDIR/bin/ddemangle.o
	$DMD -w -de -c DustMite/dustmite.d DustMite/splitter.d -of=$TERMUX_PKG_BUILDDIR/bin/dustmite.o
	$CC $TERMUX_PKG_BUILDDIR/bin/rdmd.o $D_LDFLAGS -o $TERMUX_PKG_BUILDDIR/bin/rdmd
	$CC $TERMUX_PKG_BUILDDIR/bin/ddemangle.o $D_LDFLAGS -o $TERMUX_PKG_BUILDDIR/bin/ddemangle
	$CC $TERMUX_PKG_BUILDDIR/bin/dustmite.o $D_LDFLAGS -o $TERMUX_PKG_BUILDDIR/bin/dustmite

	cd $TERMUX_PKG_SRCDIR/dub
	$DMD -O -w -version=DubUseCurl -version=DubApplication -Isource -c @build-files.txt -of=$TERMUX_PKG_BUILDDIR/bin/dub.o
	$CC $TERMUX_PKG_BUILDDIR/bin/dub.o $D_LDFLAGS -o $TERMUX_PKG_BUILDDIR/bin/dub
}

termux_step_make_install() {
	cp bin/{ddemangle,dub,dustmite,ldc-build-runtime,ldc2,ldmd2,rdmd} $TERMUX_PREFIX/bin
	cp $TERMUX_PKG_BUILDDIR/ldc-build-runtime.tmp/lib/*.a $TERMUX_PREFIX/lib
	sed "s|$TERMUX_PREFIX/|%%ldcbinarypath%%/../|g" bin/ldc2_install.conf > $TERMUX_PREFIX/etc/ldc2.conf
	cat $TERMUX_PREFIX/etc/ldc2.conf

	rm -Rf $TERMUX_PREFIX/include/d
	mkdir $TERMUX_PREFIX/include/d
	cp -r $TERMUX_PKG_SRCDIR/runtime/druntime/src/{core,etc,ldc,object.d} $TERMUX_PREFIX/include/d
	cp $LDC_PATH/import/ldc/gccbuiltins_{aarch64,arm,x86}.di $TERMUX_PREFIX/include/d/ldc
	cp -r $TERMUX_PKG_SRCDIR/runtime/phobos/etc/c $TERMUX_PREFIX/include/d/etc
	rm -Rf $TERMUX_PREFIX/include/d/etc/c/zlib
	cp -r $TERMUX_PKG_SRCDIR/runtime/phobos/std $TERMUX_PREFIX/include/d

	rm -Rf $TERMUX_PREFIX/share/ldc
	mkdir $TERMUX_PREFIX/share/ldc
	cp -r $TERMUX_PKG_SRCDIR/{LICENSE,README,packaging/bash_completion.d} $TERMUX_PREFIX/share/ldc
}
