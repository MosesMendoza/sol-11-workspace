#!/bin/bash

set -e

DEPS="http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz"
BASEDIR="$HOME/cross-compiler"

make_dirs(){
  echo "creating directories"
  pushd $HOME
    mkdir -p ${BASEDIR}/build/pkgconfig
    mkdir -p ${BASEDIR}/{unpacked,root,sources}
  popd
  echo "done"
}

get_deps(){
  echo "Retrieving deps"
  pushd $BASEDIR/sources
    for dep in $DEPS ; do
      wget $dep
    done
  popd
}

clean(){
  echo "cleaning basedir"
  rm -rf $BASEDIR
  echo "done"
}

clean_deps(){
  rm -rf $BASEDIR/build/pkgconfig
  rm -rf $BASEDIR/root
  rm -rf $BASEDIR/unpacked/pkg-config-0.28
}

unpack_deps(){
  echo "unpacking deps"
  pushd $BASEDIR/unpacked
    tar -xf $BASEDIR/sources/pkg-config-0.28.tar.gz
  popd
}

build_deps(){
  echo "building pkgconfig"
  pushd $BASEDIR/build/pkgconfig
    $BASEDIR/unpacked/pkg-config-0.28/configure --with-internal-glib
    /usr/bin/gmake
    sudo /usr/bin/gmake install DESTDIR="$BASEDIR/root"
  popd
}

if [ "$1" = "clean" ] ; then
  clean
fi


clean_deps
make_dirs
get_deps
unpack_deps
build_deps


