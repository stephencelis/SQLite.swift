#!/bin/sh
# running this script installs pre-commit and enables it on all newly cloned repositories (affects only the user that runs the script)
# to test pre-commit on one repository before enabling it on all repos, please run "brew install pre-commit" to install pre-commit
# and run "pre-commit install" to install the git hook scripts in the given repository
brew install pre-commit
git config --global init.templateDir ~/.git-template
pre-commit init-templatedir ~/.git-template