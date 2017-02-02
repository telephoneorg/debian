#!/bin/bash

set -e

: ${RELEASE:=debian/jessie}

export RELEASE

docker build -t $DOCKER_USER/${RELEASE/\//:} $(dirname $0)
docker run -i --rm $DOCKER_USER/${RELEASE/\//:} bash -lc env
