SOURCEURL="http://enterprise.delivery.puppetlabs.net/sources"
SOURCES="augeas-1.1.0.tar.gz"
BASEDIR="$HOME/pe"
PREFIX="/opt/puppet"

make_dirs(){
  echo "creating directories"
  mkdir -p $BASEDIR/build/augeas
  mkdir -p $BASEDIR/{unpacked,sources}
  sudo mkdir -p $PREFIX
  sudo chown $USER $PREFIX
  echo "done"
}

get_sources(){
  echo "Retrieving sources"
  pushd $BASEDIR/sources
    for source in $SOURCES ; do
      wget $SOURCEURL/$source
    done
  popd
}

clean(){
  echo "cleaning $BASEDIR"
  sudo rm -rf $BASEDIR
  echo "done"

  echo "cleaning $PREFIX"
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

clean
make_dirs
get_sources
unpack_sources

