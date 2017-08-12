#!/usr/bin/env bash


base=$(dirname $0)


if [[ -a $base/vars.env ]]; then
    source $base/vars.env
    export $(split -d'=' -f1 $base/vars.env)
fi

if [[ ! -z $DOCKER_PASSES ]]; then
    export DOCKER_PASS=${DOCKER_PASSES[joeblackwaslike]}
fi

for codename in ${BUILD_CODENAMES//,/ }; do
    RELEASE=debian/$codename make
    RELEASE=debian/$codename push-image
done
