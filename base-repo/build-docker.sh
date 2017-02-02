#!/bin/bash

set -e

base=$(dirname $0)

docker build -t $DOCKER_USER/debian:latest $base
docker run -i --rm $DOCKER_USER/debian:latest bash -lc env
