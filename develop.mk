

include common.mk


site:
	@echo "put your git url on the end of this command like so"
	@echo "make develop-site-[pantheon-site-id/name]"
	exit 1


site-%:
	[[-d $* ]] && make develop-clone-$* || true

clone-%:  ## Clone site
	LOCAL_GIT_COMMAND="$($*_GIT_COMMAND)"
ifeq (${LOCAL_GIT_COMMAND},)
	@echo "Override where this repo is cloned from by setting $*_GIT_COMMAND variable in .envrc"
	@echo "Otherwise we get this value from terminus: like so"
	LOCAL_GIT_COMMAND=$(call getGitRepoCloneCommand,$*)
endif
	@echo $*_GIT_COMMAND



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


