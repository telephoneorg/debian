#!/bin/bash

set -e

base=$(dirname $0)
: ${RELEASE:=debian/jessie}
export RELEASE

mkdir -p $base/build

$base/builder/run chanko-upgrade -f
$base/builder/run make clean
$base/builder/run make
