
PROJECT_NAME ?= $(shell basename $(shell git rev-parse --show-toplevel))
REPO_NAME    ?= ${DOCKER_IMAGE_ORG}/${DOCKER_PROJECT_PREFIX}-${PROJECT_NAME}
VCS_REF      ?= $(shell git rev-parse --short HEAD)
DATE_TAG     ?= $(shell TZ=UTC date +%Y-%m-%d_%H.%M)
VERSION      ?= $(shell git describe --tags --always --dirty --match="v*" 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null || echo v0)


## [[ todo: have these be params for the make command ]]

ifndef IMAGE_TAG
	ifdef CIRCLE_BUILD_NUM
		IMAGE_TAG:=$(CIRCLE_BUILD_NUM).git$(VCS_REF)
	else
		IMAGE_TAG:=latest
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


define getGitRepoCloneCommand
$(shell terminus connection:info $(1).dev --format=json | jq ".git_command")
endef


##
## help message system
##
help: ## Print list of tasks and descriptions.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-38s\033[0m %s\n", $$1, $$2}'

