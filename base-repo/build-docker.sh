#!/bin/bash

set -e

base=$(dirname $0)

docker build -t $DOCKER_USER/latest $base
docker run -i --rm $DOCKER_USER/latest bash -lc env
