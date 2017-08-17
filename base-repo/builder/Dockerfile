FROM tklx/base:0.1.0

# custom components: chanko, pool, repo, fab and their deps
COPY debs /tmp/debs
RUN set -x \
    && sed 's/httpredir/ftp.us/g' /etc/apt/sources.list.d/sources.list \
    && echo "nameserver 8.8.8.8" > /etc/resolv.conf \
    && apt-get update \
    && dpkg -i /tmp/debs/*.deb || true \
    && apt-get -y -f install \
    && apt-get -y install upx git curl ca-certificates \
    && rm -rf /tmp/debs \
    && apt-clean --aggressive

COPY debootstrap/generic /usr/share/debootstrap/scripts/generic
COPY entrypoint /entrypoint

ENV FAB_PATH=/turnkey/fab
ENTRYPOINT ["/entrypoint"]
CMD ["/bin/bash"]
