# syntax=docker/dockerfile:1

ARG FRANKENPHP_BUILD_PLATFORM=linux/amd64
FROM --platform=${FRANKENPHP_BUILD_PLATFORM} dunglas/frankenphp:static-builder-gnu AS builder

WORKDIR /go/src/app

# CentOS 7 does not ship re2c in its standard repositories. static-php-cli's
# doctor requires it before the build starts, so enable EPEL explicitly.
RUN yum install -y epel-release && \
    yum install -y re2c && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN --mount=type=secret,id=github-token \
    GITHUB_TOKEN="$(if [ -r /run/secrets/github-token ]; then cat /run/secrets/github-token; fi)" \
    CLEAN=1 \
    PHP_VERSION=8.5 \
    PHP_EXTENSIONS="ctype,curl,dom,exif,fileinfo,filter,iconv,imagick,intl,libxml,mbstring,mysqli,openssl,opcache,pdo_mysql,redis,session,simplexml,tokenizer,xml,xmlreader,xmlwriter,zip,phar,mongodb" \
    SPC_OPT_DOWNLOAD_ARGS="--ignore-cache-sources=php-src --retry 5 -G mongodb:2.1.9:https://github.com/mongodb/mongo-php-driver.git" \
    ./build-static.sh

FROM scratch

COPY --from=builder /go/src/app/dist/frankenphp-linux-x86_64 /frankenphp-linux-x86_64
