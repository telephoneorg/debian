#!/bin/bash

set -e

: ${RELEASE:=debian/jessie}
: ${DOCKER_ACCOUNT:=callforamerica}

export RELEASE DOCKER_ACCOUNT

docker push $DOCKER_ACCOUNT/${RELEASE/\//:}

