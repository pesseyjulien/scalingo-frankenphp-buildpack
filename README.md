# FrankenPHP buildpack pour Scalingo

Ce dépôt fournit un buildpack Scalingo qui installe une version précompilée de FrankenPHP dans l’application.
Le code de l’application reste dans le répertoire de build Scalingo : il n’est pas intégré au binaire FrankenPHP.

## Contenu du buildpack

- `bin/detect` : active le buildpack lorsqu’un `composer.json` est présent.
- `bin/compile` : télécharge le binaire FrankenPHP, vérifie éventuellement son SHA-256 et installe les dépendances Composer de production.
- `bin/release` : configure le processus `web` Scalingo.
- `Dockerfile` : construit le binaire FrankenPHP utilisé par les releases.
- `.github/workflows/release.yml` : construit et publie le binaire lorsqu’un tag `v*` est poussé.

## Runtime et extensions

Le runtime publié est :

- Linux `x86_64` / amd64 ;
- basé sur glibc, avec l’image officielle `dunglas/frankenphp:static-builder-gnu` ;
- PHP 8.5 ;
- extension `mongodb` 2.1.9 ;
- support Caddy/FrankenPHP en mode classique.

Extensions PHP compilées dans le binaire :

```text
ctype curl dom exif fileinfo filter gd iconv imagick intl libxml mbstring
mysqli openssl opcache pdo_mysql phar redis session simplexml tokenizer
xml xmlreader xmlwriter zip mongodb
```

`json` est intégré à PHP 8.5 et ne nécessite pas d’être compilé séparément.

## Construire le runtime

Prérequis : Docker avec BuildKit et un accès réseau.

En local, un token GitHub est recommandé pour éviter les limites de téléchargement lors de la récupération des sources :

```sh
export GITHUB_TOKEN=<github-token>
docker build \
  --platform linux/amd64 \
  --secret id=github-token,env=GITHUB_TOKEN \
  --file Dockerfile \
  --tag frankenphp-runtime .
```

Extraire ensuite le binaire :

```sh
docker create --name frankenphp-runtime-tmp frankenphp-runtime
docker cp frankenphp-runtime-tmp:/frankenphp-linux-x86_64 ./frankenphp-linux-x86_64
docker rm frankenphp-runtime-tmp

chmod +x ./frankenphp-linux-x86_64
./frankenphp-linux-x86_64 php-cli -r 'echo PHP_VERSION, " ", phpversion("mongodb"), PHP_EOL;'
sha256sum ./frankenphp-linux-x86_64 > ./frankenphp-linux-x86_64.sha256
```

Le workflow GitHub Actions effectue automatiquement ces étapes et publie les deux fichiers lorsqu’un tag `v*` est poussé. Il utilise le `GITHUB_TOKEN` fourni automatiquement par GitHub Actions.

## Utiliser le buildpack sur Scalingo

Publier ce dépôt sur GitHub, puis publier le binaire et son fichier SHA-256 dans une release GitHub. Configurer ensuite l’application Scalingo :

```sh
scalingo --app <app> env-set \
  BUILDPACK_URL=https://github.com/<org>/scalingo-frankenphp-buildpack.git \
  FRANKENPHP_BINARY_URL=https://github.com/<org>/scalingo-frankenphp-buildpack/releases/download/v<version>/frankenphp-linux-x86_64 \
  FRANKENPHP_BINARY_SHA256=<sha256-du-binaire>
```

L’application doit fournir un `Caddyfile` à sa racine. Le processus `web` est lancé avec :

```text
bin/frankenphp run --config Caddyfile
```

Le `Caddyfile` doit écouter sur le port fourni par Scalingo, généralement `$PORT`.

Si un `composer.json` est présent, le buildpack exécute :

- `composer install --no-dev` ;
- génération de l’autoload optimisé et classmap authoritative ;
- `composer check-platform-reqs`.

Les valeurs par défaut du processus web sont :

```text
FRANKENPHP_NUM_THREADS=2
FRANKENPHP_MAX_THREADS=4
```

Elles peuvent être modifiées dans les variables d’environnement Scalingo.
