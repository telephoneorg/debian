#!/bin/bash

set -e

: ${RELEASE:=debian/jessie}
: ${DOCKER_ACCOUNT:=callforamerica}

export RELEASE DOCKER_ACCOUNT

mkdir -p build

builder/run chanko-upgrade
builder/run make clean
builder/run make

docker build -t $DOCKER_ACCOUNT/${RELEASE/\//:} .
docker run -i --rm $DOCKER_ACCOUNT/${RELEASE/\//:} bash -lc env

