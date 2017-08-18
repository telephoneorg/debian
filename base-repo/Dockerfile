FROM scratch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     CODENAME
ENV     CODENAME=${CODENAME:-jessie}

LABEL   os="linux" \
        os.distro="debian" \
        os.version="$CODENAME"

ADD build/rootfs.tar.gz /

RUN mkdir /goss
