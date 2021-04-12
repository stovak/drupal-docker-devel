
include common.mk


emit-%:      ## emit k8s for project.
	make k8s-emit-nginx-$*
	make k8s-emit-php-$*
	make k8s-emit-mysql-$*
	make k8s-emit-solr-$*

emit-nginx-%:
	K8S_DIR ?= $(call getSourceYamlTemplateFolder,nginx)
	K8S_BUILD_DIR="./$${*}/build_k8s"
	K8S_FILES=$$(call getYamlFilesInDir,$$K8S_DIR)
	make k8s-emit-files-$*

emit-php-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,php)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make k8s-emit-files-$*

emit-mysql-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,mysql)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make k8s-emit-files-$*

emit-solr-%:
	K8S_DIR=$(call getSourceYamlTemplateFolder,solr)
	K8S_BUILD_DIR=./${*}/build_k8s
	K8S_FILES=$(call getYamlFilesInDir,$$K8S_DIR)
	make k8s-emit-files-$*


build-files-%:
	@mkdir -p $*/$(K8S_BUILD_DIR)
	@for file in $(K8S_FILES); do \
		mkdir -p `dirname "$(K8S_BUILD_DIR)/$$file"` ; \
		$(SHELL_EXPORT) envsubst <$(K8S_DIR)/$$file >$(K8S_BUILD_DIR)/$$file ;\
	done


