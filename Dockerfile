FROM alpine:3.7

ENV NGINX_VERSION 1.13.8
ENV PCRE_VERSION 8.41
ENV ZLIB_VERSION 1.2.11
ENV CC gcc

WORKDIR /app
RUN apk update \
  && apk add --no-cache \
    pcre \
    zlib \
    openssl \
    gettext \
  && apk add --no-cache --virtual .build-deps \
    curl \
    gcc \
    build-base \
    linux-headers \
    libressl-dev \
  && cd /tmp \
  && curl -s https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz | tar xvz \
  && curl -s http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz | tar xvz \
  && curl -s http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xvz \
  && cd nginx-${NGINX_VERSION} \
  && export CORES=$(nproc --all) \
  && ./configure \
    --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --user=nginx \
    --group=nginx \
    --with-pcre=../pcre-${PCRE_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-http_ssl_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-http_v2_module \
    --with-ipv6 \
    --with-threads \
    --with-http_realip_module \
    --with-file-aio \
    --with-http_sub_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
  && make -j$(($CORES + $CORES / 2)) \
  && make install \
  && adduser -D nginx \
  && mkdir -p /var/cache/nginx \
  && apk del .build-deps \
  && rm -rf /tmp/*
