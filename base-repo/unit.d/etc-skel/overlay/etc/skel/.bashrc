#!/bin/sh

set -e

if [ -d ~/bashrc.d ]
then
    for file in ~/bashrc.d/*
    do
        if [ -r $file ]
        then
            . $file
        fi
    done
    unset file
fi

set +e

