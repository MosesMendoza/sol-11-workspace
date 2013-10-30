#!/bin/bash

workdir="pkg/ips/workdir"
proto="$workdir/proto"
repo="$workdir/repo"
pkgs="pkg/ips/pkgs"
repouri="file:///export/home/moses/$repo"
project="gcc-binutils-sparc"
version="4.5.4,5.11-0"
artifact="$pkgs/$project@$version.p5p"
home="/export/home/moses/"
code="/opt/gcc-sparc"

clean(){
  echo "cleaning"
  sudo rm -f $workdir/$project.p5m.x
  sudo rm -f $workdir/$project.depends
  sudo rm -f $workdir/$project.depends.res
  sudo rm -f $workdir/$project.p5m
  sudo rm -f $workdir/transforms
  sudo rm -r $repo
  sudo rm -r $pkgs
  sudo rm -r $proto
}

setup(){
  echo "setting up"
  mkdir -p $repo
  mkdir -p $pkgs
  mkdir -p $proto/opt
  mkdir -p $proto/usr/bin
  sudo mv $code $proto/opt/
  pushd $proto/usr/bin
    for f in ../../opt/gcc-sparc/bin/sparc-* ; do
      ln -s $f .
    done
  popd
}

protogen(){
  echo "proto generating"
  pkgsend generate $proto >> $workdir/$project.p5m.x
}

# Because of the sparc sysroot, we don't actually generate deps for the package
# All hell would break loose. Ask me how I know.
protodeps(){
  echo "generating dependencies"
  pkgdepend generate -d $proto $workdir/$project.p5m.x > $workdir/$project.depends
  pkgdepend resolve -m $workdir/$project.depends
  cat $workdir/$project.depends.res >> $workdir/$project.p5m.x
}

writetransforms(){
  echo "Writing transforms"
  print -r '
<transform file dir link hardlink path=usr/share/man/.+(/.+)? -> default facet.doc.man true>

# saner dependencies
<transform depend -> edit fmri "@[^ \t\n\r\f\v]*" "">

<transform dir path=usr->drop>
<transform dir path=usr/bin->drop>

# drop opt
<transform dir path=opt->drop>' > $workdir/transforms
}

protomogrify(){
  echo "mogrifying.."
  pkgmogrify $workdir/transforms $workdir/$project.p5m.x | pkgfmt >> $workdir/$project.p5m
}

addfmri(){
  echo '
set name=pkg.fmri value="pkg://puppetlabs.com/developer/gcc-binutils-sparc@4.5.4,5.11-0"
set name=pkg.summary value="gcc cross-compiler for sparc w/binutils"
set name=pkg.human-version value=4.5.4
set name=pkg.description value="gcc cross-compiler for sparc w/binutils built-in"
set name=variant.arch value=i386' >> $workdir/$project.p5m
}

createrepo(){
  echo "creating repo"
  pkgrepo create $repo
  pkgrepo set -s $repo publisher/prefix=puppetlabs.com
}

send(){
  echo "sending to repo"
  pkgsend -s $repouri publish -d $proto --fmri-in-manifest $workdir/$project.p5m
}

recv(){
  echo "receiving from repo"
  pkgrecv -s $repouri -a -d $artifact $project@$version
  mv $artifact $home
}

clean
setup
protogen
writetransforms
protomogrify
addfmri
createrepo
send
recv

