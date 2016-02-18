#!/usr/bin/env bash

echo ">>> Installing Node Version Manager"

# Install NVM
github_username="fideloper"
github_repo="Vaprobash"
github_branch="1.4.2"
github_url="https://raw.githubusercontent.com/${github_username}/${github_repo}/${github_branch}"
curl --silent -L ${github_url}/helpers/nvm_install.sh | sh

exit 1;

NODEJS_VERSION="latest"
NODE_PACKAGES=[
  "grunt-cli",
  "gulp",
  "bower",
]

echo ">>> Installing Node.js version ${NODEJS_VERSION}"
echo "    This will also be set as the default node version"

# If set to latest, get the current node version from the home page
if [[ ${NODEJS_VERSION} -eq "latest" ]]; then
    NODEJS_VERSION="node"
fi

# Install Node
nvm install ${NODEJS_VERSION}

# Set a default node version and start using it
nvm alias default ${NODEJS_VERSION}

nvm use default

npm install -g ${NODE_PACKAGES[@]}
