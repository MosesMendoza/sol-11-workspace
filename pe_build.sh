BASEDIR="${HOME}/pe"
PREFIX="/opt/puppet"
PATH="/opt/gcc-sparc/bin:/usr/local/bin:${PATH}"
SFWLIBS="/usr/sfw/lib"
CROSSGCCLIBS="/opt/gcc-sparc/sparc-sun-solaris2.11/lib"

CC="/opt/gcc-sparc/bin/sparc-sun-solaris2.11-gcc"
CFLAGS="-I${PREFIX}/include"
LDFLAGS="-L${CROSSGCCLIBS} \
         -Wl,-rpath-link,${CROSSGCCLIBS} \
         -Wl,-rpath,${PREFIX}/lib \
         -Wl,-rpath,${SFWLIBS}"

export LDFLAGS PREFIX PATH CFLAGS CC

echo "LDFLAGS is $LDFLAGS"
echo "CFLAGS is $CFLAGS"

clean(){
  echo "cleaning"
  sudo rm -rf ${BASEDIR}/build/augeas/*
  sudo rm -rf ${PREFIX}/*
  echo "done"
}

patch(){
  echo "patching"
  pushd ${BASEDIR}/unpacked/augeas-1.1.0
    /usr/bin/gsed -i 's,Cflags: -I${includedir},Cflags: -I${includedir} -I/usr/include/libxml2,g' augeas.pc.in
  popd
  echo "done"
}

sysprep(){
  [ -f /usr/include/wctype.h ] && sudo mv /usr/include/wctype.h /tmp
}

sysunprep(){
  [ -f /tmp/wctype.h ] && sudo mv /tmp/wctype.h /usr/include
}

build_augeas(){
  echo "building augeas"
  pushd ${BASEDIR}/build/augeas
    ${BASEDIR}/unpacked/augeas-1.1.0/configure --prefix=${PREFIX} \
                                             --host="sparc-sun-solaris2.11" \
                                             CC="$CC" \
                                             LDFLAGS="$LDFLAGS" \
                                             CFLAGS="$CFLAGS"
    sudo /usr/bin/gmake -j4
    sudo /usr/bin/gmake install
  popd
}

clean
#patch
#sysprep
build_augeas
#sysunprep
