

include common.mk




clone:  ## Clone site
	if [! -d "./local-copies/${PANTHEON_SITE_NAME}" ]
		GIT_URL=`vendor/bin/terminus.phar connection:info ${PANTHEON_SITE_NAME}.dev --field=git_url`
		git clone ${GIT_URL} ./local-copies/${PANTHEON_SITE_NAME}
	fi


source-site-git-%:
ifndef PANTHEON_SITE_NAME
	@echo "You should only use this when the PANTHEON_SITE_NAME is set like so:"
	@echo "export PANTHEON_SITE_NAME={site-name-goes-here}"
	@exit 1
endif
ifeq ($*,)
	@echo "put your git url on the end of this command like so"
	@echo "make source-site-git-git@github.com:pantheon-systems/drops-8"
	exit 1
endif
	git clone $* ${PANTHEON_SITE_NAME}


