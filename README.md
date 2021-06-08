# Project Demigods

This project allows me to get up and running on developing a pantheon-based job in less than 10 minutes.

# usage

BEFORE: Clone this repo to a place on your local machine and `cd` to the directory.



From the repo directory:

1.  Install the command line dependencies:

    MAC:

    1. Ensure [homebrew](https://brew.sh) is installed:

       `which brew` should return something like `/usr/local/bin/brew`

    1. `brew bundle install`

    WIN10:

    1. Follow the instructions to ensure cyg-win is installed:

    2. `cyg-get install direnv imagemagick jq libyaml make php@7.4 wget yq`

# TODO: validate these windows commands ^^^

1.  `make firstrun`

1.  Ensure that your personal environment variables are set inside this folder:

    1. `echo "export PANTHEON_SITE_NAME=${PANTHEON_SITE_NAME}" >> .envrc`

    1. `echo "export PANTHEON_EMAIL_ADDRESS=${PANTHEON_EMAIL_ADDRESS}" >> .envrc`

    1. `direnv allow`

# TODO: validate these commands on windows machine ^^^

    Now typing `env` should show all the variables in your environment inlcuding the
    ones you just set. When you CD outside of the directory, DIRENV will remove them
    from your shell. It's recommended to not put these values in a text file and check
    them in and for them to remain ephemeral. The repos will ignore the .envrc file
    and it should not be checked in.

1.  Authorize terminus to interact with pantheon on your account

    `vendor/bin/terminus.phar auth:login --email=${PANTHEON_EMAIL_ADDRESS}`

1.  What is the source of truth of your site's code? Is it pantheon?

    ✗  NO: `make clone-git-{git-address}`

       if you use a build-server like circleCI your primary repository might reside outside pantheon


    ✓  YES: `make clone-site-${PANTHEON_SITE_ID}`


1.  copy down a docker-compose file, latest templated makefile and a cursory
    readme:

    `make run ${PANTHEON_SITE_NAME}`

1.  Open the cloned site in your text editor.

    Your site should be cloned to the `/${PANTHEON_SITENAME}` folder inside this repo's clone.


## Warning 02JUN2021: USE AT YOUR OWN RISK. This is still very much a work-in-progress.
