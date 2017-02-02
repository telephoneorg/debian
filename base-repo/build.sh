#!/bin/bash

set -e

: ${RELEASE:=debian/jessie}

base=$(dirname $0)
export RELEASE DOCKER_USER

mkdir -p $base/build

$base/builder/run chanko-upgrade
$base/builder/run make clean
$base/builder/run make
