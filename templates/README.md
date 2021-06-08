# Simple Docker Compose

Allows development for Pantheon's default Drupal 9 upstream.

## Step 1

Clone your site to a directory on your disk then cd to that directory.

## Step 2

Create the following docker-compose file in your site's root directory as `docker-compose.yml`

```yaml
# Use this docker-compose file to host the site locally
version: "3.7"
services:
  nginx:
    container_name: nginx
    image: stovak/project-demigods-nginx:latest
    expose:
      - 80
      - 9222
    depends_on:
      - php
      - mysql
    links:
      - php
      - mysql
    volumes:
      - ".:/var/www"
    ports:
      - "8080:80"
      - "443:443"
      - "9222:9222"
    env_file:
      - .env

  php:
    container_name: php
    image: stovak/project-demigods-php:latest
    expose:
      - "9000"
    ports:
      - "9000:9000"
    external_links:
      - solr-ssl_solr-network:milkensolr-nginx
    volumes:
      - ".:/var/www"
      - "$HOME/.terminus/cache:/root/.terminus/cache:cached"
      - type: bind
        source: $HOME/.ssh
        target: /root/.ssh
        read_only: true
    links:
      - redis
      - mysql
    env_file:
      - .env
    environment:
      - BACKUP_FILE_NAME=backup.sql.gz
      - DATABASE_NAME=drupal8

  mysql:
    container_name: mysql
    image: stovak/project-demigods-mysql:latest
    expose:
      - "3306"
    ports:
      - "33067:3306"
    env_file:
      - .env

  redis:
    container_name: redis
    image: redis
    expose:
      - "6379"

volumes:
  web: {}
  initmysql: {}
```

Add this file to your next commit:

`git add docker-compose.yml`

## Step 3

Create the following file as `.env` in the root of the repository.

```.env
# copy to /.env
## Basic Vars
ENV=local
BABEL_ENV=legacy
NODE_ENV=development

## COMPOSER
COMPOSER_ALLOW_SUPERUSER=1
DRUPAL_MAJOR_VERSION=8

## MYSQL
MYSQL_ROOT_PASSWORD=drupal
MYSQL_USER=Mahabharata-Pandu
MYSQL_PASSWORD=Shantanu-Ganga
MYSQL_DATABASE=drupal8

## REDIS
CACHE_HOST=redis
CACHE_PORT=6379

## DRUPAL_SPECIFIC
PREPROCESS_CSS=FALSE
PREPROCESS_JS=FALSE
DB_DRIVER=mysql
DB_HOST=mysql
DB_NAME=drupal8
DB_USER=Mahabharata-Pandu
DB_PASSWORD=Shantanu-Ganga
DB_PORT=3306
DRUPAL_SYSTEM_LOGGING_ERROR_LEVEL=verbose
DRUPAL_HASH_SALT=lDRPmMvzNIBzmBs4bvLXBot/r4uju6XZiiON3UolHQc=
DRUSH_OPTIONS_URI=localhost:8080

## SOLR
SOLR_HOST=solr
SOLR_PORT=8983
SOLR_PATH=\/solr
SOLR_CORE=${PANTHEON_SITE_NAME}
NODE_TESTING_URL=https://live-$ {PANTHEON_SITE_NAME}.pantheonsite.io
```

Do not commit this file; add it to the `.gitignore`: `echo ".env" >> .gitignore`

## Step 4

Copy this file to web/sites/default/settings.local.php

```php
<?php

if (!defined('PANTHEON_ENVIRONMENT')) {
  $env = getenv('ENV');
  $databases['default']['default'] = [
    'database' => getenv('DB_NAME'),
    'username' => getenv('DB_USER'),
    'password' => getenv('DB_PASSWORD'),
    'host' => getenv('DB_HOST'),
    'port' => getenv('DB_PORT'),
    'driver' => getenv('DB_DRIVER'),
    'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
    'prefix' => '',
    'collation' => 'utf8mb4_general_ci',
  ];
  $settings['hash_salt'] = $_SERVER['DRUPAL_HASH_SALT'];
  $settings['cache']['bins']['config'] = 'cache.backend.chainedfast';
  $redis_host = getenv('CACHE_HOST');
  if (PHP_SAPI == 'cli') {
    ini_set('max_execution_time', 999);
  }
  else {
    $settings['container_yamls'][] = 'modules/contrib/redis/example.services.yml';
    $settings['redis.connection']['interface'] = 'PhpRedis';
    $settings['redis.connection']['host'] = getenv('CACHE_HOST');
    $settings['redis.connection']['port'] = getenv('CACHE_PORT');
    $settings['cache']['bins']['bootstrap'] = 'cache.backend.redis';
    $settings['cache']['bins']['config'] = 'cache.backend.redis';
    $settings['cache']['bins']['render'] = 'cache.backend.redis';
  }


  $config['system.logging']['error_level'] = getenv('DRUPAL_SYSTEM_LOGGING_ERROR_LEVEL');

  $settings['extension_discovery_scan_tests'] = TRUE;
  $settings['rebuild_access'] = FALSE;
  $settings['skip_permissions_hardening'] = TRUE;

  $settings['file_public_path'] = 'sites/default/files';
  $settings['file_private_path'] = 'sites/default/private';
  $settings["file_temp_path"] = 'sites/default/temp';
  $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';

}

```

## Step 5

To automate common tasks, create a `Makefile` in the root directory

```makefile

$(shell sh ./.env)
PANTHEON_SITE_NAME?=$(shell basename $(shell pwd))
BACKUP_FILE_NAME=${PANTHEON_SITE_NAME}.sql.gz
LIVE_SITE=${PANTHEON_SITE_NAME}.live


env:
	@[ ! -f ./.envrc ] && make firstrun || true


build: env ## install dependencies and compile JS
	make build-composer
	make build-webpack


build-composer: env ./composer.json  ## composer install
	composer install-vendor-dir

build-webpack: env   ## npm install && npm run build
	npm install
	npm run build

run: ## run the docker containers for a development environment
	make run-docker

run-docker: env
	$(shell docker-compose up -d) > /dev/null

run-clone-livedb: env ## clone the live DB to the docker mysql instance
	@echo "** If terminus is set up incorrectly on this machine, the database download will fail. **"
	@[[ -f "./db/${BACKUP_FILE_NAME}" ]] && rm "./db/${BACKUP_FILE_NAME}" || true
	terminus backup:create ${LIVE_SITE} --element=database --yes > /dev/null
	terminus backup:get ${LIVE_SITE} --element=database --yes --to="./db/${BACKUP_FILE_NAME}" > /dev/null
	[[ -f "db/${BACKUP_FILE_NAME}" ]] && make run-clone-restore && true

run-clone-livefiles:
	@echo
	SFTP_COMMAND=$(shell terminus connection:info ${PANTHEON_SITE_NAME}.live --format=json | jq -r ".sftp_command") > /dev/null
	SSH_COMMAND=${SFTP_COMMAND}/sftp -o Port=/ssh -p /
	FILES_FOLDER=`realpath db/files`
	FILES_SYMLINK=`realpath web/sites/default`

  ## YOUR SSH KEY MUST BE REGISTERED WITH PANTHEON AND SHARED WITH THE DOCKER CONTAINER FOR THIS TO WORK
	rsync -rvlz --copy-unsafe-links --size-only --checksum --ipv4 --progress -e '${SFTP_COMMAND}:files/ ${FILES_FOLDER}

	rm -Rf web/sites/default/files
	ln -s ${FILES_FOLDER} ${FILES_SYMLINK}



upgrade:  ## Run upgrade for composer and NPM
	make upgrade-composer
	make upgrade-npm

upgrade-composer:  ## Run composer upgrade
	composer update-vendor-dir

upgrade-npm:  ## Run npm upgrade && npm audit fix
	npm upgrade
	npm audit fix

run-clone-restore:
	# This makes the assumption that you are running a development version
	# with the supplied docker-compose.
	$(shell pv "./db/${BACKUP_FILE_NAME}" | gunzip | mysql -u root --password=${MYSQL_ROOT_PASSWORD} --host 127.0.0.1 --port 33067 --protocol tcp ${DB_NAME}) > /dev/null

authterminus-%: ## authorize terminus usage:  make authterminus-{EMAIL_ADDRESS}  e.g. make authterminus-you@email.com
	## This command assumes terminus is correctly set up
	## RE: https://github.com/pantheon-systems/terminus
	terminus auth:login --email=$* > /dev/null

firstrun: ## make environemnt vars available
	@echo
	cp .envrc.dist .envrc
	cp .env.dist .env
	direnv allow

lint: ## Lint, me baby. Do it long, do it hard. Do it now. (oh! my!)
	@echo
	composer install-codestandards
	composer code-fix
	composer code-sniff
	## npm run lint

log-me-in:
	local COMMAND_LINE_USER=${USER}
	@echo **TODO**: fix this so that it dynamicly parses the docker-compose and gets the id of the php container.
	@echo "This command assumes the php-container is called mi-php. Change that value or get it to work"
	open "$(docker exec -it mi-php "drush uli ${COMMAND_LINE_USER}")"

_install_mac:
	# TODO for windows
	brew install direnv kubernetes-cli jq yq docker make git pv gunzip


how-to-use:  ## Instructions for using this makefile
	@echo
	@echo
	@echo "Step 1: docker-compose -d "
	@echo "        start up the docker containers to host the site"
	@echo
	@echo "Step 2: make authterminus-{pantheon-account-email-address]"
	@echo "        Authorize terminus to interact with pantheon on your account."
	@echo
	@echo "Step 3: make run-clone-livedb"
	@echo "        Copies down the database from the live environment."
	@echo
	@echo "Step 4: make run-clone-livefiles"
	@echo "        Copy the files directory down loadlly."
	@echo
	@echo
	@echo


show-important-vars:
	@echo
	@echo "=================================================================="
	@echo "ENVIRONMENT VARIABLES:"
	@echo PANTHEON_SITE_NAME=${PANTHEON_SITE_NAME}
	@echo BACKUP_FILE_NAME=${BACKUP_FILE_NAME}
	@echo LIVE_SITE=${LIVE_SITE}
	@echo "=================================================================="



.DEFAULT_GOAL := help

##
## help message system
##
help: ## print list of tasks and descriptions
	make show-important-vars
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-38s\033[0m %s\n", $$1, $$2}'



.DEFAULT_GOAL := help



```
