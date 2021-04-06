
PROJECT_NAME ?= $(shell basename $(shell git rev-parse --show-toplevel))
REPO_NAME ?= ${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}
VCS_REF ?= $(shell git rev-parse --short HEAD)
DATE_TAG ?= $(shell TZ=UTC date +%Y-%m-%d_%H.%M)
VERSION ?= $(shell git describe --tags --always --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null || echo v0)


## [[ todo: have these be params for the make command ]]

ifndef IMAGE_TAG
	ifdef CIRCLE_BUILD_NUM
		IMAGE_TAG:=$(CIRCLE_BUILD_NUM).git$(VCS_REF)
	else
		IMAGE_TAG:=dev-$(VCS_REF)
	endif
endif

ifndef BUILD_ID
	ifdef CIRCLE_BUILD_NUM
		BUILD_ID:=${CIRCLE_BUILD_NUM}
	else
		BUILD_ID:=${USER}-${VERSION}-$(VCS_REF)
	endif
endif

# only need this for circle
ifdef CIRCLE_BUILD_NUM
		QUAY := docker login -p "$${DOCKER_IMAGE_HOST}_PASSWD" -u "$${DOCKER_IMAGE_HOST}_USER" ${DOCKER_IMAGE_HOST}
endif


PHP_CONTAINER=$(call getServiceContainerTag,php)
NGINX_CONTAINER=$(call getServiceContainerTag,nginx)
MYSQL_CONTAINER=$(call getServiceContainerTag,mysql)


PHONY: env envrc
env: ./.envrc
	[[ ! -f '.envrc' ]] && make firstrun || true
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

MAKE_ENV += PROJECT_NAME REPO_NAME VCS_REF DATE_TAG VERSION BUILD_ID PHP_CONTAINER NGINX_CONTAINER MYSQL_CONTAINER

SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))' )



firstrun:
	# if it doesn't exist, copy .envrc.dist .envrc and allow
	cp .envrc.dist .envrc
	[[ -f '.env' ]] && mv .env .env.deprecated
	@echo "The .env file has ben deprecated in favor of the direnv pattern"
	@echo "of making an .envrc file for the directory"
	@echo "Then doing a direnv allow so that entering into the directory "
	@echo "sets the correct env vars."
	@echo  "original .env file moved to .env.deprecated"
	direnv allow


clean: env ## Tidy up docker's plumbing,
	# yes, every one of these do something slightly different...
	docker system prune -f
	docker container prune  -f
	docker image prune -f
	docker network prune -f
	docker volume prune -f

PHONY: build

build: env ## Build all containers
	make build-containers

build-containers: env ## Synonym Build all containers
	make build-docker-nginx
	make build-docker-php
	make build-docker-mysql
	make build-docker-solr

build-docker-%: env ## Build single container {nginx,php,mysql,solr}
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${VERSION}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		--tag=$(call getServiceContainerTag,$*) \
		 ./$*-container

pull: ## Pull containers down from ${DOCKER_IMAGE_HOST}.
	make pull-nginx
	make pull-php
	make pull-mysql
	make pull-solr

pull-%:
	SERVICE=$*
	docker pull "$${SERVICE}_CONTAINER"


push: ## Push containers up to ${DOCKER_IMAGE_HOST}.
	make push-nginx
	make push-php
	make push-mysql
	make push-solr

push-%:
	SERVICE=$*
	docker push "$${SERVICE}_CONTAINER"







emit-k8s-%:
	make emit-nginx-k8s-$*
	make emit-php-k8s-$*
	make emit-mysql-k8s-$*
	make emit-solr-k8s-$*

emit-nginx-k8s-%:
	K8S_DIR ?= $(call getSourceYamlTemplateFolder,nginx)
	K8S_BUILD_DIR="./$${*}/build_k8s"
	K8S_FILES=$$(call getYamlFilesInDir,$$K8S_DIR)
	make emit-k8s-files-$*

emit-php-k8s-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,php)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make emit-k8s-files-$*

emit-mysql-k8s-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,mysql)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make emit-k8s-files-$*

emit-solr-k8s-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,solr)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make emit-k8s-files-$*


build-k8s-files-%:
	@mkdir -p $*/$(K8S_BUILD_DIR)
	@for file in $(K8S_FILES); do \
		mkdir -p `dirname "$(K8S_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(K8S_DIR)/$$file >$(K8S_BUILD_DIR)/$$file ;\
	done



## Host a pantheon site locally with kubernetes

build-site-%: ## build a site from a pantheon site ref
	[[ ! -d "./${*}" ]] && make clone-site-$* || true
	mkdir -p ${*}/web/sites/default
	cp "settings.local.php" "${*}/web/sites/default/settings.local.php"


	#make build-k8s-$*
	#cd ./$*
	$(shell cd $* && make build)




flush:
	# [[TODO: FIX ]] docker exec -t freshdrupalmi_php_1 '/var/www/vendor/bin/drush cr' && docker exec -t freshdrupalmi_redis_1 '/usr/local/bin/redis-cli FLUSHALL'






run-site-%: ## Run Makefile's RUN target for %site
	[[ ! -f "$*/docker-compose.yml" ]] $(SHELL_EXPORT) envsubst < templates/docker-compose.yml > $*/docker-compose.yml
	[[ ! -f "$*/Makefile" ]] $(SHELL_EXPORT) envsubst < templates/Makefile > $*/Makefile
	cd $* && $(shell make run)

teardown-site-%:
	cd $* && $(shell make teardown)

clone-site-%:
	git clone ${GITHUB_REPO} $*
	echo "/${*}" >> .gitignore


setup-${DOCKER_IMAGE_HOST}: ## setup docker login for image host
ifdef CIRCLE_BUILD_NUM
	ifndef ${DOCKER_IMAGE_HOST}_PASSWD
	@echo "You need to set ${DOCKER_IMAGE_HOST}_PASSWD in the cicleci envrionemnt variables."
	endif
	ifndef ${DOCKER_IMAGE_HOST}_USER
	@echo "You need to set ${DOCKER_IMAGE_HOST}_USER in the cicleci envrionemnt variables."
	endif
	@echo "Setting up quay login credentials."
	@$(${DOCKER_HOST_LOGIN_COMMAND}) > /dev/null
	else
	@echo "No docker login unless we are in CI."
	@echo "We will fail if the docker config.json does not have the quay credentials."
	endif
else
	# This command makes the assumption that you've logged in
	# via the command line at sometime in the past and are just
	# reusing the credentials.
	@docker login ${DOCKER_IMAGE_HOST}
endif



_install_mac: ## install needed utilities with homebrew
	brew install direnv kubernetes-cli jq yq docker make git envsubst
_install_wsl: ## install needed utilities with WSL
	# FOR REFERENCE: https://docs.microsoft.com/en-us/windows/wsl/about
	wsl sudo apt-get update && wsl sudo apt-get install direnv kubernetes-cli jq yq docker make git envsubst

##
## help message system
##
help: ## print list of tasks and descriptions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-38s\033[0m %s\n", $$1, $$2}'



.DEFAULT_GOAL := help

define getServiceContainerTag
${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}-$(1):${IMAGE_TAG}
endef

define getSourceYamlTemplateFolder
./$(1)-container/k8s
endef

define getYamlFilesInDir
$(shell find $(1) -name '*.yaml' | sed 's:$(1)/::g')
endef
