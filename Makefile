
PROJECT_NAME=$(basename `git rev-parse --show-toplevel`)

REPO_NAME=${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}

VCS_REF=$(shell git rev-parse --short HEAD)

DATE_TAG=$(shell TZ=UTC date +%Y-%m-%d_%H.%M)

ifndef IMAGE_TAG
	ifdef CIRCLE_BUILD_NUM
		IMAGE_TAG=$(CIRCLE_BUILD_NUM).git$(VCS_REF)
	else
		IMAGE_TAG=dev-$(VCS_REF)
	endif
endif

ifndef BUILD_ID
	ifdef CIRCLE_BUILD_NUM
		BUILD_ID=${CIRCLE_BUILD_NUM}
	else
		BUILD_ID=${USER}-$(VCS_REF)
	endif
endif

# only need this for circle
ifdef CIRCLE_BUILD_NUM
		QUAY := docker login -p "$${DOCKER_IMAGE_HOST}_PASSWD" -u "$${DOCKER_IMAGE_HOST}_USER" ${DOCKER_IMAGE_HOST}
endif


MYSQL_CONTAINER=${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}-mysql:$(IMAGE_TAG)
PHP_CONTAINER=${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}-php:$(IMAGE_TAG)
NGINX_CONTAINER=${DOCKER_IMAGE_HOST}/${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}-nginx:$(IMAGE_TAG)


env:
# if these aren't defined in envrc, define them here
ifndef DOCKER_IMAGE_HOST
	DOCKER_IMAGE_HOST=quay.io
endif

ifndef DOCKER_IMAGE_ORG
	DOCKER_IMAGE_ORG=pantheon-systems
endif

ifndef PROJECT_PREFIX
	PROJECT_PREFIX=${DOCKER_PROJECT_PREFIX}
endif

# only need this for circle
ifdef CIRCLE_BUILD_NUM
		${DOCKER_HOST_LOGIN_COMMAND} := docker login -p "$${DOCKER_IMAGE_HOST}_PASSWD" -u "$${DOCKER_IMAGE_HOST}_USER" ${DOCKER_IMAGE_HOST}
endif


firstrun: ## update .envrc
	# copy .envrc.dist .envrc and allow
	cp .envrc.dist .envrc
	# This will change env variables for only this folder
	direnv allow


clean: env ## Tidy up docker's plumbing,
	# yes, every one of these do something slightly different...
	docker system prune -f
	docker container prune  -f
	docker image prune -f
	docker network prune -f
	docker volume prune -f


build: env ## Build all containers
	make build-nginx
	make build-php
	make build-mysql

build-nginx: env ./nginx-container ## Build the development Nginx Container
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${BUILD_ID}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		-t "${NGINX_CONTAINER}" ./nginx-container

build-php: env ./php-container ## Build PHP Container
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${BUILD_ID}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		-t "${PHP_CONTAINER}" ./php-container

build-mysql: env ./mysql-container ## build Mysql Container
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${BUILD_ID}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		-t "${MYSQL_CONTAINER}" ./mysql-container

push: setup-${DOCKER_IMAGE_HOST}
	make push-nginx
	make push-php
	make push-mysql

push-nginx: ./nginx-container
	docker push ${NGINX_CONTAINER}

push-php: ./php-container
	docker push ${PHP_CONTAINER}

push-mysql:
	docker push ${MYSQL_CONTAINER}

flush:
	# [[TODO: FIX ]] docker exec -t freshdrupalmi_php_1 '/var/www/vendor/bin/drush cr' && docker exec -t freshdrupalmi_redis_1 '/usr/local/bin/redis-cli FLUSHALL'


setup-${DOCKER_IMAGE_HOST}: ## setup docker login for quay.io
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
