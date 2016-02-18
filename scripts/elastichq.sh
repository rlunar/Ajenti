#!/usr/bin/env bash

echo ">>> Installing ElasticHQ"

nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

cd /usr/share/
sudo curl --silent -L https://github.com/royrusso/elasticsearch-HQ/tarball/master | sudo tar -xz
sudo mv *elasticsearch-HQ*/ elastichq/
cd ~
