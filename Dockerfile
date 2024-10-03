FROM quay.io/mittwald/kube-httpcache:v0.8.1 AS builder

ENV VARNISH_VERSION=73
ENV VARNISH_VERSION_DOT=7.3

WORKDIR /

RUN set -x && \
    apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash && \
    apt-get -qq install git make automake libtool python3-sphinx varnish-dev && \
    apt-get -qq purge curl gnupg && \
    apt-get -qq autoremove && apt-get -qq autoclean && \
    rm -rf /var/cache/*

RUN git clone --branch ${VARNISH_VERSION_DOT} --single-branch https://github.com/varnish/varnish-modules.git

WORKDIR /varnish-modules

RUN ./bootstrap && \
    ./configure && \
    make && \
    make check -j 4 && \
    make install

FROM quay.io/mittwald/kube-httpcache:v0.8.1 AS final

COPY --from=builder /usr/lib/varnish/vmods/ /usr/lib/varnish/vmods/

ENTRYPOINT  [ "/kube-httpcache" ]
