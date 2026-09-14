# FrankenPHP buildpack for Scalingo

This proof-of-concept buildpack downloads a prebuilt static FrankenPHP
artifact. It embeds the application, PHP 8.5, and the required PHP extensions.
At build time it refuses artifacts unless they report PHP 8.5 and exactly
`ext-mongodb` 2.1.9.

The application repository's `docker/frankenphp/Dockerfile` is the reference
build for the required runtime. It clones the official `mongo-php-driver` tag
`2.1.9` with its submodules because that driver version is not available on
PECL:

```sh
docker build --file docker/frankenphp/Dockerfile \
  --tag addict-api-frankenphp-poc-mongodb-2-1-9 .
docker run --rm --entrypoint frankenphp addict-api-frankenphp-poc-mongodb-2-1-9 \
  php-cli -r 'echo PHP_VERSION, " ", phpversion("mongodb"), PHP_EOL;'
```

It prints `8.5.x 2.1.9`. Producing a static Linux amd64 artifact for Scalingo
requires a CI build that applies the same source pin; the generic static
extension catalogue is deliberately not used because it cannot pin MongoDB to
2.1.9. Once that artifact is published, use this buildpack as follows.

Publish this directory as its own Git repository, then configure the Scalingo
application with its URL:

```sh
scalingo --app <app> env-set \
  BUILDPACK_URL=https://github.com/<org>/scalingo-frankenphp-buildpack.git \
  FRANKENPHP_BINARY_URL=https://<artifact-host>/frankenphp-linux-x86_64 \
  FRANKENPHP_BINARY_SHA256=<sha256>
```

The `web` process is supplied by `bin/release`. It runs FrankenPHP with the
project `Caddyfile`, which listens in HTTP on `$PORT`; Scalingo terminates TLS
before forwarding requests to the application.
