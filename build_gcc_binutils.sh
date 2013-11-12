#!/bin/bash

set -e

# Use /opt/gcc-sparc for prefix for binutils and gcc
#
# We'll have things like bin, lib, libexec, share, and sparc-sun-solaris2.11 under it
#

SOURCEURL="http://enterprise.delivery.puppetlabs.net/sources/solaris"
SOURCES="binutils-2.23.2.tar.gz gcc-4.5.4.tar.gz"
HEADERS="sparc.sysroot.tar.gz"
PATCHES="binutils-2.23.2-common.h.patch"

BASEDIR="$HOME/cross-compiler"
export PREFIX="/opt/gcc-sparc"
export SYSROOT="$PREFIX/sparc-sysroot"
export TARGET="sparc-sun-solaris2.11"
export PATH="$PREFIX/bin:$PATH"

echo "SYSROOT is $SYSROOT"
echo "PREFIX is $PREFIX"
echo "PATH is $PATH"
echo "TARGET is $TARGET"

make_dirs(){
  echo "creating directories"
  pushd $HOME
    mkdir -p ${BASEDIR}/build/{gcc-sparc,binutils-sparc}
    mkdir -p ${BASEDIR}/{unpacked,sources}
    sudo mkdir -p $PREFIX
    sudo chown $USER $PREFIX
    mkdir -p $SYSROOT
  popd
  echo "done"
}


get_sources(){
  echo "Retrieving sources"
  pushd $BASEDIR/sources
    for source in $SOURCES ; do
      wget $SOURCEURL/$source
    done
  popd
  echo "done"
}

get_patches(){
  echo "Retrieving patches"
  pushd $BASEDIR/sources
    for p in $PATCHES ; do
      wget $SOURCEURL/patches/$p
    done
  popd
  echo "done"
}

get_headers(){
  echo "retrieving headers"
  pushd $BASEDIR/sources
    wget $SOURCEURL/$HEADERS
  popd
  echo "done"
}

clean(){
  echo "cleaning sources"
  for source in $SOURCES ; do
    sudo rm -f $source
  done
  echo "done"

  echo "cleaning patches"
  for patch in $PATCHES ; do
    sudo rm -f $patch
  done
  echo "done"

  echo "cleaning basedir"
  sudo rm -rf $BASEDIR
  echo "done"

  echo "cleaning prefix"
  sudo rm -rf $PREFIX
  echo "done"
}

unpack_sources(){
  echo "unpacking sources"
  pushd $BASEDIR/unpacked
    for tarball in $SOURCES ; do
      tar -xf $BASEDIR/sources/$tarball
    done
  popd
  echo "done"
}
unpack_headers(){
  echo "unpacking headers"
  pushd $SYSROOT
    tar -xf $BASEDIR/sources/$HEADERS
  popd
  echo "done"
}

patches(){
  echo "patching"
  pushd "${BASEDIR}/unpacked/binutils-2.23.2/include/elf"
    patch -p0 < "${BASEDIR}/sources/binutils-2.23.2-common.h.patch"
  popd
  echo "done"
}

build_binutils(){
  echo "building binutils"
  pushd $BASEDIR/build/binutils-sparc
    $BASEDIR/unpacked/binutils-2.23.2/configure --target=$TARGET \
                                                --prefix=$PREFIX \
                                                --with-sysroot=$SYSROOT \
                                                --disable-nls \
                                                -v
    /usr/bin/gmake -j4
    /usr/bin/gmake install
  popd
  echo "done"
}

build_gcc(){
  echo "building gcc"
  pushd $BASEDIR/build/gcc-sparc
    $BASEDIR/unpacked/gcc-4.5.4/configure --target=$TARGET \
                                          --prefix=$PREFIX \
                                          --with-sysroot=$SYSROOT \
                                          --disable-nls \
                                          --with-gmp-include=/usr/include/gmp \
                                          --with-gmp-lib=/usr/lib \
                                          --with-mpfr-include=/usr/include/mpfr \
                                          --with-mpfr-lib=/usr/lib \
                                          --with-mpc-include=/usr/include \
                                          --with-mpc-lib=/usr/lib \
                                          --with-gnu-as \
                                          --with-as="$PREFIX/bin/sparc-sun-solaris2.11-as" \
                                          --with-gnu-ld \
                                          --with-ld="$PREFIX/bin/sparc-sun-solaris2.11-ld" \
                                          --disable-libgcj \
                                          -v
    /usr/bin/gmake -j4
    /usr/bin/gmake install
  popd
}

if [ "$1" = "binutils" ] ; then
  echo "This script will build binutils"
  if [ "$2" = "gcc" ] ; then
    echo "This script will build gcc"
  fi
elif [ "$1" = "gcc" ] ; then
  echo "This script will build binutils and gcc"
else
  echo "You supplied the following arguments: $@"
  echo 'Script requires "binutils" or "gcc" as argument, or "binutils gcc"'
  exit 1
fi

clean
make_dirs
get_sources
get_patches
get_headers
unpack_sources
unpack_headers
patches

if [ "$1" = "binutils" ] || [ "$1" = "gcc" ] ; then
  build_binutils
fi

if [ "$1" = "gcc" ] || [ "$2" = "gcc" ] ; then
  build_gcc
fi

