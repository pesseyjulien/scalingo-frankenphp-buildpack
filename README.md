# FrankenPHP buildpack for Scalingo

This proof-of-concept buildpack downloads a prebuilt static FrankenPHP runtime.
The application source remains in the Scalingo build directory. At build time,
the buildpack refuses artifacts unless they report PHP 8.5 and exactly
`ext-mongodb` 2.1.9.

The repository `Dockerfile` builds the generic Linux amd64 runtime. It forces
the official `mongo-php-driver` tag `2.1.9`, because that driver version is not
available on PECL:

```sh
docker build --file Dockerfile --tag frankenphp-runtime .
docker create --name frankenphp-runtime-tmp frankenphp-runtime
docker cp frankenphp-runtime-tmp:/frankenphp-linux-x86_64 ./frankenphp-linux-x86_64
docker rm frankenphp-runtime-tmp
./frankenphp-linux-x86_64 php-cli -r 'echo PHP_VERSION, " ", phpversion("mongodb"), PHP_EOL;'
```

It prints `8.5.x 2.1.9`. The GitHub Actions workflow publishes this runtime and
its SHA-256 file when a `v*` tag is pushed. Configure Scalingo with that release:

Publish this directory as its own Git repository, then configure the Scalingo
application with its URL:

```sh
scalingo --app <app> env-set \
  BUILDPACK_URL=https://github.com/<org>/scalingo-frankenphp-buildpack.git \
  FRANKENPHP_BINARY_URL=https://github.com/pesseyjulien/scalingo-frankenphp-buildpack/releases/download/v<version>/frankenphp-linux-x86_64 \
  FRANKENPHP_BINARY_SHA256=<sha256-from-frankenphp-linux-x86_64.sha256>
```

The `web` process is supplied by `bin/release`. It runs FrankenPHP with the
project `Caddyfile`, which listens in HTTP on `$PORT`; Scalingo terminates TLS
before forwarding requests to the application.

When `composer.json` is present, the buildpack installs production dependencies
with the downloaded FrankenPHP runtime.
