



_install_mac: ## install needed utilities with homebrew.
	brew update && brew upgrade && brew install direnv kubernetes-cli jq yq docker make git envsubst
_install_wsl: ## install needed utilities with WSL.
	# FOR REFERENCE: https://docs.microsoft.com/en-us/windows/wsl/about
	wsl sudo apt-get update && wsl sudo apt-get install direnv kubernetes-cli jq yq docker make git envsubst
