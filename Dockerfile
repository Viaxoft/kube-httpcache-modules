FROM quay.io/mittwald/kube-httpcache:v0.9.1 AS builder

ENV VARNISH_VERSION=76
ENV VARNISH_VERSION_DOT=7.6

WORKDIR /

RUN set -x && \
    apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash && \
    apt-get -qq install git make automake libtool python3-sphinx varnish-dev && \
    apt-get -qq purge curl gnupg && \
    apt-get -qq autoremove && apt-get -qq autoclean && \
    rm -rf /var/cache/* && rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${VARNISH_VERSION_DOT} --single-branch https://github.com/varnish/varnish-modules.git

WORKDIR /varnish-modules

RUN ./bootstrap && \
    ./configure && \
    make && \
    make check -j 4 && \
    make install

FROM quay.io/mittwald/kube-httpcache:v0.9.1 AS final

# Reinstall last minor Varnish version
ENV VARNISH_VERSION=76
RUN apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_VERSION}/script.deb.sh | bash && \
    apt-get -qq update && apt-get -qq install varnish && \
    apt-get -qq purge curl gnupg && \
    apt-get -qq autoremove && apt-get -qq autoclean && \
    rm -rf /var/cache/* && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/lib/varnish/vmods/ /usr/lib/varnish/vmods/

ENTRYPOINT  [ "/kube-httpcache" ]
