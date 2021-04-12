

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
