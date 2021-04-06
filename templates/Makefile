
$(shell sh ./.env)
PANTHEON_SITE_NAME?=$(shell basename $(shell pwd))
BACKUP_FILE_NAME=${PANTHEON_SITE_NAME}.sql.gz
LIVE_SITE=${PANTHEON_SITE_NAME}.live


env:
	@[ ! -f ./.envrc ] && make firstrun || true



build: env ## install dependencies and compile JS
	make build-php-composer
	make build-node-webpack


build-php-composer: env ./composer.json ## composer install
	$(shell composer install-vendor-dir)

build-node-webpack: env ## npm install && npm run build
	$(shell npm install && npm run build) > /dev/null

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

run-clone-restore:
	# This makes the assumption that you are running a development version
	# with the supplied docker-compose.
	$(shell pv "./db/${BACKUP_FILE_NAME}" | gunzip | mysql -u root --password=${MYSQL_ROOT_PASSWORD} --host 127.0.0.1 --port 33067 --protocol tcp ${DB_NAME}) > /dev/null

authterminus-%: ## authorize terminus usage:  make authterminus-{EMAIL_ADDRESS}  e.g. make authterminus-you@email.com
	## This command assumes terminus is correctly set up
	## RE: https://github.com/pantheon-systems/terminus
	terminus auth:login --email=$* > /dev/null

firstrun: ## make environemnt vars available
	cp .envrc.dist .envrc
	cp .env.dist .env
	direnv allow

log-me-in:
	local COMMAND_LINE_USER=${USER}
	open "$(docker exec -it mi-php "drush uli ${COMMAND_LINE_USER}")"

_install_mac:
	# TODO for windows
	brew install direnv kubernetes-cli jq yq docker make git pv gunzip

.DEFAULT_GOAL := help

##
## help message system
##
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-38s\033[0m %s\n", $$1, $$2}'



.DEFAULT_GOAL := help

