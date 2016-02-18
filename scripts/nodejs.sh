#!/usr/bin/env bash

echo ">>> Installing Node Version Manager"

# Install NVM
curl --silent -L $GITHUB_URL/helpers/nvm_install.sh | sh

NODEJS_VERSION = "latest"
NODE_PACKAGES = [
  "grunt-cli",
  "gulp",
  "bower",
]

echo ">>> Installing Node.js version ${NODEJS_VERSION}"
echo "    This will also be set as the default node version"

# If set to latest, get the current node version from the home page
if [[ ${NODEJS_VERSION} -eq "latest" ]]; then
    {NODEJS_VERSION}="node"
fi

# Install Node
nvm install ${NODEJS_VERSION}

# Set a default node version and start using it
nvm alias default ${NODEJS_VERSION}

nvm use default

npm install -g ${NODE_PACKAGES[@]}
