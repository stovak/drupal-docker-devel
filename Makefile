
include common.mk


PHONY: env envrc
env: ./.envrc
	@[[ ! -f '.envrc' ]] && make firstrun || true
# if these aren't defined in envrc, define them here
ifndef DOCKER_IMAGE_HOST
	DOCKER_IMAGE_HOST=quay.io
endif

ifndef DOCKER_IMAGE_ORG
	DOCKER_IMAGE_ORG=pantheon-systems
endif

# only need this for circle
ifdef CIRCLE_BUILD_NUM
		${DOCKER_HOST_LOGIN_COMMAND} := docker login -p "$${DOCKER_IMAGE_HOST}_PASSWD" -u "$${DOCKER_IMAGE_HOST}_USER" ${DOCKER_IMAGE_HOST}
endif

PHP_CONTAINER=$(call getServiceContainerTag,php)
NGINX_CONTAINER=$(call getServiceContainerTag,nginx)
MYSQL_CONTAINER=$(call getServiceContainerTag,mysql)
SOLR_CONTAINER=$(call getServiceContainerTag,solr)
MAKE_ENV += PROJECT_NAME REPO_NAME VCS_REF DATE_TAG VERSION BUILD_ID PHP_CONTAINER NGINX_CONTAINER MYSQL_CONTAINER
SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))' )



firstrun:    ## You should need to run this only once.
	# if it doesn't exist, copy .envrc.dist .envrc and allow
	cp .envrc.dist .envrc
	[[ -f '.env' ]] && mv .env .env.deprecated
	@echo "The .env file has ben deprecated in favor of the direnv pattern"
	@echo "of making an .envrc file for the directory"
	@echo "Then doing a direnv allow so that entering into the directory "
	@echo "sets the correct env vars."
	@echo  "original .env file moved to .env.deprecated"
	direnv allow




docker-%: env     ## Build all containers.
	make -f docker.mk $*

develop-%: env    ## Development build commands
	make -f develop.mk $*




source-site: env ## Create a source-site for a pantheon-to-pantheon upgrade
	@echo "This is actually a pseudo command to get you instructions"
	@echo
	@echo
	@echo "If you have a site that uses Pantheon Build Tools and your"
	@echo "builds run on a build service like **CIRCLE CI**"
	@echo "clone the repo locally with the following command:"
	@echo "echo 'export PANTHEON_SITE_NAME={PANTHEON_SITE_NAME}' >> .envrc"
	@echo "make source-site-git-{GITREPO_URL}"
	@echo
	@echo
	@echo
	@echo
	@echo





build-site-%:   ## build a site from a pantheon site.
	@echo "Building site... "
ifeq ($(*),)
	@echo "Usage: make build-site-PANTHEON_SITENAME"
	@echo "e.g. make build-site-freshdrupalmi"
	exit 1
endif
	make copy-docker-hosting-files-$*
	cd ./$* && make install

copy-docker-hosting-files-%: ## Copy latest docker local hosting files.
	make copy-settings-local-$*
	make copy-copy-docker-compose-$*
	make copy-makefile-$*

copy-settings-local-%:   ## Copy settings.local.php into PANTHEON_SITE_NAME.
	mkdir -p ${*}/web/sites/default
	cp "templates/settings.local.php" "${*}/web/sites/default/settings.local.php"

copy-docker-compose-%:   ## Copy docker-compose.yml into PANTHEON_SITE_NAME.
	$(SHELL_EXPORT) PROJECT_NAME=${PROJECT_NAME} envsubst < templates/docker-compose.yml > $*/docker-compose.yml

copy-makefile-%:   ## Copy latest makefile into site.
	cp templates/Makefile $*/Makefile

flush:
	# [[TODO: FIX ]] docker exec -t freshdrupalmi_php_1 '/var/www/vendor/bin/drush cr' && docker exec -t freshdrupalmi_redis_1 '/usr/local/bin/redis-cli FLUSHALL'

run-site-%: ## Run Makefile's RUN target for given site.


teardown-site-%:
	cd $* && $(shell make teardown)

clone-site-%:
	git clone ${GITHUB_REPO} $*
	echo "/${*}" >> .gitignore


setup-${DOCKER_IMAGE_HOST}: ## setup docker login for image host.
ifdef CIRCLE_BUILD_NUM
	ifndef ${DOCKER_IMAGE_HOST}_PASSWD
	@echo "You need to set ${DOCKER_IMAGE_HOST}_PASSWD in the cicleci envrionemnt variables."
	endif
	ifndef ${DOCKER_IMAGE_HOST}_USER
	@echo "You need to set ${DOCKER_IMAGE_HOST}_USER in the cicleci envrionemnt variables".
	endif
	@echo "Setting up quay login credentials."
	@$(${DOCKER_HOST_LOGIN_COMMAND}) > /dev/null
	else
	@echo "No docker login unless we are in CI."
	@echo "We will fail if the docker config.json does not have the quay credentials".
	endif
else
	# This command makes the assumption that you've logged in
	# via the command line at sometime in the past and are just
	# reusing the credentials.
	@docker login ${DOCKER_IMAGE_HOST}
endif






how-to-use:  ## Instructions for using this makefile
	@echo
	@echo
	@echo "Step 1:  make authterminus-{pantheon-account-email-address]"
	@echo "         Authorize terminus to interact with pantheon on your account"
	@echo
	@echo "Step 2a: make clone-git-{git-address}"
	@echo "         if you use a build-server like circleCI your primary repository might reside outside pantheon"
	@echo ""
	@echo "Step 2b: make clone-pantheon-{PANTHEON_SITE_NAME}"
	@echo "         if your primary repo is at pantheon, run this with the site name as"
	@echo "         the argument (e.g. 'make clone-pantheon-example-pantheon-site')."
	@echo
	@echo "Step 3:  make run"
	@echo "         copy down a docker-compose file, latest templated makefile and a cursory"
	@echo "         readme, cd to repo and do a 'make run'."
	@echo
	@echo "Step 4:  cd ${PANTHEON_SITE_NAME} && make build"
	@echo "         Run the make command in the pantheon site... now go develop."
	@echo "         readme, cd to repo and do a 'make run'."
	@echo
	@echo "Step 5:  make create-destination-%"
	@echo "         Create a new pantheon site from the new d9 upstream."
	@echo
	@echo



show-important-vars: env
	@echo
	@echo "=================================================================="
	@echo "IMPORTANT ENVIRONMENT VARIABLES:"
	@echo DOCKER_IMAGE_HOST=${DOCKER_IMAGE_HOST}
	@echo DOCKER_IMAGE_ORG=${DOCKER_IMAGE_ORG}
	@echo DOCKER_PROJECT_PREFIX=${DOCKER_PROJECT_PREFIX}
	@echo PANTHEON_SITE_NAME=${PANTHEON_SITE_NAME}
	@echo SOURCE_SITE_REPO=${SOURCE_SITE_REPO}
	@echo DEST_SITE_REPO=${DEST_SITE_REPO}
	@echo "=================================================================="



.DEFAULT_GOAL := help

define getServiceContainer
${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}-$(1)
endef

define getServiceContainerTag
$(call getServiceContainer,$(1)):${IMAGE_TAG}
endef

define getSourceYamlTemplateFolder
./$(1)-container/k8s
endef

define getYamlFilesInDir
$(shell find $(1) -name '*.yaml' | sed 's:$(1)/::g')
endef
