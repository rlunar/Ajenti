#!/usr/bin/env bash

# Update Package List
apt-get update

# Update System Packages
apt-get -y upgrade

echo "Setting Timezone & Locale to EST & en_US.UTF-8"

sudo ln -sf /usr/share/zoneinfo/EST /etc/localtime
sudo apt-get install -qq language-pack-en
sudo locale-gen en_US
sudo update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

echo ">>> Installing Base Packages"

# Install base packages

# Antivirus
apt-get install -qq clamav
apt-get install -qq clamav-daemon

# Basic Tools ##############################################################
apt-get install -qq build-essential 
apt-get install -qq software-properties-common
apt-get install -qq python-software-properties

apt-get install -qq ack-grep
apt-get install -qq dos2unix
apt-get install -qq cachefilesd
apt-get install -qq curl
apt-get install -qq gcc
apt-get install -qq git-core
apt-get install -qq libmcrypt4
apt-get install -qq libpcre3-dev
apt-get install -qq make
apt-get install -qq nano
apt-get install -qq openssh-server
apt-get install -qq p7zip-full
apt-get install -qq python2.7-dev
apt-get install -qq python-pip
apt-get install -qq re2c
apt-get install -qq supervisor
apt-get install -qq unattended-upgrades
apt-get install -qq unzip
apt-get install -qq whois
apt-get install -qq vim
apt-get install -qq zip

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

echo ">>> Installing PHP"
apt-get install -qq dbus
apt-get install -qq php5-common
apt-get install -qq php5-cli
apt-get install -qq php5-curl
apt-get install -qq php5-gd
apt-get install -qq php5-gmp
apt-get install -qq php5-imagick
apt-get install -qq php5-intl
apt-get install -qq php5-json
apt-get install -qq php5-memcached
apt-get install -qq php5-mcrypt
apt-get install -qq php5-mysqlnd
apt-get install -qq php5-redis
apt-get install -qq php5-sqlite
apt-get install -qq php5-xsl
apt-get install -qq php-pear
service ajenti restart

echo ">>> Installing SQLite Server"
sudo apt-get install -qq sqlite
