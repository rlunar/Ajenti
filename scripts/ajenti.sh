#!/usr/bin/env bash

# MySQL Root Password [P@$$w0r|)]
if [ -z "${1}" ]; then
    ROOT_USER_PASS="P@\$\$w0r|)"
else
    ROOT_USER_PASS=${1}
fi
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "mysql-server mysql-server/data-dir select ''"
debconf-set-selections <<< "mysql-server mysql-server/root-pass password ${ROOT_USER_PASS}"
debconf-set-selections <<< "mysql-server mysql-server/re-root-pass password ${ROOT_USER_PASS}"

# Ajenti ######################################################################
echo ">>> Installing Ajenti"
apt-get remove apache2
wget -O- https://raw.github.com/ajenti/ajenti/1.x/scripts/install-ubuntu.sh | sudo sh
apt-get install -qq ajenti-v
apt-get install -qq ajenti-v-nginx
apt-get install -qq ajenti-v-mysql
apt-get install -qq ajenti-v-php-fpm
apt-get install -qq ajenti-v-mail
apt-get install -qq ajenti-v-python-gunicorn
apt-get install -qq ajenti-v-nodejs
service ajenti restart
