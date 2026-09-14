FROM dunglas/frankenphp:static-builder-musl AS builder

WORKDIR /go/src/app

RUN PHP_VERSION=8.5 \
    PHP_EXTENSIONS="curl,dom,exif,fileinfo,imagick,intl,mbstring,mysqli,opcache,pdo_mysql,redis,simplexml,xml,xmlreader,xmlwriter,zip,mongodb" \
    PHP_EXTENSION_LIBS="ldap" \
    SPC_OPT_DOWNLOAD_ARGS="--ignore-cache-sources=php-src --retry 5 -G mongodb:2.1.9:https://github.com/mongodb/mongo-php-driver.git" \
    ./build-static.sh

FROM scratch

COPY --from=builder /go/src/app/dist/frankenphp-linux-x86_64 /frankenphp-linux-x86_64
