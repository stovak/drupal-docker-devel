#!/bin/bash

set -e

source ${HOME}/.bashrc

if [ -d "/tmp/www" ]; then
  cp -R /tmp/www /var
fi

if [ "${1#-}" != "$1" ]; then
	set -- /usr/bin/supervisor "$@"
fi

exec "$@"
