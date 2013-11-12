#!/bin/bash

workdir="pkg/ips/workdir"
proto="$workdir/proto"
repo="$workdir/repo"
pkgs="pkg/ips/pkgs"
repouri="file:///export/home/moses/$repo"
project="pkgconfig"
version="0.28,5.11-0"
artifact="$pkgs/$project@$version.p5p"
code="$HOME/cross-compiler/root"

clean(){
  echo "cleaning"
  rm -f $workdir/$project.p5m.x
  rm -f $workdir/$project.depends
  rm -f $workdir/$project.depends.res
  rm -f $workdir/$project.p5m
  rm -f $workdir/transforms
  rm -r $repo
  rm -r $pkgs
}

setup(){
  echo "setting up"
  mkdir -p $repo
  mkdir -p $pkgs
  mkdir -p $proto
  sudo cp -r $code/* $proto
}

protogen(){
  echo "proto generating"
  pkgsend generate $proto >> $workdir/$project.p5m.x
}

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
<transform dir path=usr/local->drop>
<transform dir path=usr/local/bin->drop>' > $workdir/transforms
}

protomogrify(){
  echo "mogrifying.."
  pkgmogrify $workdir/transforms $workdir/$project.p5m.x | pkgfmt >> $workdir/$project.p5m
}

addfmri(){
  echo '
set name=pkg.fmri value="pkg://puppetlabs.com/developer/pkgconfig@0.28.0,5.11-0"
set name=pkg.summary value="pkgconfig tool"
set name=pkg.human-version value=0.28.0
set name=pkg.description value="pkg-config built for solaris 11"
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
  mv $artifact $HOME/
}

clean
setup
protogen
protodeps
writetransforms
protomogrify
addfmri
createrepo
send
recv

