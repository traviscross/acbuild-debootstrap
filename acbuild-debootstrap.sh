#!/bin/sh
##### -*- mode:shell-script; indent-tabs-mode:nil; sh-basic-offset:2 -*-
# Copyright (c) 2017 Travis Cross <tc@traviscross.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

usage () {
  echo "Usage: $0 [-h]">&2
  echo "     -n <pkg_name>">&2
  echo "    [-d <workdir>]">&2
  echo "    [-m <mode>]">&2
  echo "    [-o <output_img>]">&2
}

err () {
  echo "Error: $1">&2
  exit 1
}

wdir=""
mode="assemble"
pkgname=""
output_img=""
debootstrap_variant="minbase"
debootstrap_suite="jessie"
while getopts "d:hm:n:o:s:" o; do
  case "$o" in
    d) wdir="$OPTARG" ;;
    h) usage; exit 0 ;;
    m) mode="$OPTARG" ;;
    n) pkgname="$OPTARG" ;;
    o) output_img="$OPTARG" ;;
    s) debootstrap_suite="$OPTARG" ;;
  esac
done
shift $(($OPTIND-1))

test -n "$pkgname" || {
  echo "Error: package name not provided\n">&2
  usage
  exit 1
}
test -n "$output_img" || output_img="${pkgname}.aci"

set -e
blocked_signals="INT HUP QUIT TERM USR1"

test $(id -u) -eq 0 \
  || err "Error: must be root"

bdir="$(dirname "$0")"
test -n "$wdir" || wdir="${bdir}/tmp"
rdir="${wdir}/rootfs"
ddir="${wdir}/distro"
ac_begun=false
do_clean=false

ac () { acbuild --debug "$@"; }
acbegin () { ac_begun=true; ac begin "$@"; }
acend () { $ac_begun && { ac_begun=false; ac end "$@"; };}

cleanup () {
  set +e
  trap - $blocked_signals EXIT
  echo "## Cleaning up...">&2
  acend
  $do_clean && {
    mountpoint -q "$wdir" && {
      umount "$wdir" || err "Could not umount tmpfs"
    }
    test -d "$wdir" && {
      rmdir "$wdir" || err "Could not remove working directory"
    }
  }
}

init_wdir () {
  echo "## Mounting working tmpfs directory...">&2
  mkdir -p "$wdir" || err "Couldn't create working directory"
  test -d "$wdir" || err "Failed to create working directory"
  mount -t tmpfs -o size=500M,mode=750 none "$wdir" \
    || err "Couldn't mount tmpfs for working directory"
}

debstrap () {
  debootstrap \
    --merged-usr \
    --include=dbus \
    --variant=$debootstrap_variant \
    $debootstrap_suite \
    "$@"
}

bootstrap () {
  mountpoint -q "$wdir" || init_wdir
  echo "## Running debootstrap...">&2
  debstrap "$ddir"
}

build () {
  test -d "$ddir" || bootstrap
  echo "## Building container...">&2
  rm -rf "$rdir"
  cp -Tal "$ddir" "$rdir"
  find "$rdir"/var/cache/apt/archives -type f -name "*.deb" \
    | xargs rm -f
}

assemble () {
  test -d "$rdir" || build
  echo "## Assembling container into $output_img...">&2
  find "$rdir"/var/lib/apt/lists -type f \
    | xargs rm -f
  acbegin "$rdir"
  acbuild set-name "$pkgname"
  acbuild set-working-dir /tmp
  acbuild set-exec -- true
  acbuild write --overwrite "$output_img"
  acend
}

trap 'exit 1' $blocked_signals
trap cleanup EXIT

test "$mode" = "clean" && {
  do_clean=true
  exit 0
}
test "$mode" = "init" && { init_wdir; exit 0; }
test "$mode" = "bootstrap" && { bootstrap; exit 0; }
test "$mode" = "build" && { build; exit 0; }
test "$mode" = "assemble" && { assemble; exit 0; }
err "Unknown mode"
