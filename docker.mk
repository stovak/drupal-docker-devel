

include common.mk

build:      ## Synonym Build all containers.
	make docker-build-nginx
	make docker-build-php
	make docker-build-mysql
	make docker-build-solr



build-%:     ## Build single container {nginx,php,mysql,solr}.
	docker build \
		--build-arg BUILD_DATE="${DATE_TAG}" \
		--build-arg VCS_REF="${VCS_REF}" \
		--build-arg VERSION="${VERSION}" \
		--build-arg REPO_NAME="${REPO_NAME}" \
		--tag=$(call getServiceContainer,$*):latest \
		 ./$*-container


pull:     ## Pull containers down from ${DOCKER_IMAGE_HOST}.
	make docker-pull-nginx
	make docker-pull-php
	make docker-pull-mysql
	make docker-pull-solr

pull-%:     ## Pull individual containers e.g. make pull-nginx.
	docker pull $(call getServiceContainerTag,$*)

push:     ## Push containers up to ${DOCKER_IMAGE_HOST}.
	make docker-push-nginx
	make docker-push-php
	make docker-push-mysql
	make docker-push-solr

push-%:      ## Push individual containers e.g. make push-nginx.
	docker push $(call getServiceContainerTag,$*)

clean:     ## Tidy up docker's plumbing,
	# yes, every one of these do something slightly different...
	docker system prune -f
	docker container prune  -f
	docker image prune -f
	docker network prune -f
	docker volume prune -f
