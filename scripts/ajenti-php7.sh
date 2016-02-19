#!/usr/bin/env bash
#
# https://github.com/Eugeny/ajenti-v/pull/213

# Install add-apt-repository requisites
apt-get install -y software-properties-common
apt-get install -y pkg-config
apt-get install -y git-core autoconf bison libxml2-dev libbz2-dev libmcrypt-dev libcurl4-openssl-dev libltdl-dev libpng-dev libpspell-dev libreadline-dev make

# Ajenti ######################################################################
echo ">>> Installing Ajenti"
apt-get remove apache2
wget -O- https://raw.github.com/ajenti/ajenti/1.x/scripts/install-ubuntu.sh | sudo sh
apt-get install -qq ajenti-v
apt-get install -qq ajenti-v-nginx
apt-get install -qq ajenti-v-mysql
apt-get install -qq ajenti-v-php-fpm

# Add ppa:ondrej/php repository
add-apt-repository ppa:ondrej/php
apt-get update

# Purge old php5 and ajenti-v-php-fpm
apt-get purge -qq ajenti-v-php-fpm
apt-get purge -qq php5-*
apt-get autoremove -qq
apt-get --purge autoremove

# Install php5.6 & php7.0
apt-get install -qq php5.6-fpm php5.6-mysql php7.0-fpm php7.0-mysql
apt-get install -qq dbus

apt-get install -qq ajenti-v-php5.6-fpm

apt-get install -qq php5.6-common
apt-get install -qq php5.6-cli
apt-get install -qq php5.6-curl
apt-get install -qq php5.6-gd
apt-get install -qq php5.6-gmp
apt-get install -qq php5.6-intl
apt-get install -qq php5.6-json
apt-get install -qq php5.6-mcrypt
apt-get install -qq php5.6-pgsql
apt-get install -qq php5.6-sqlite
apt-get install -qq php5.6-xsl
apt-get install -qq php-pear

# apt-get install -qq php5.6-imagick
# apt-get install -qq php5.6-mysqlnd
# apt-get install -qq php5.6-redis
# apt-get install -qq php5.6-memcached


apt-get install -qq ajenti-v-php7.0-fpm

apt-get install -qq php7.0-common
apt-get install -qq php7.0-dev 
apt-get install -qq php7.0-bz2
apt-get install -qq php7.0-cli
apt-get install -qq php7.0-curl
apt-get install -qq php7.0-gd
apt-get install -qq php7.0-gmp
apt-get install -qq php7.0-intl
apt-get install -qq php7.0-imap
apt-get install -qq php7.0-json
apt-get install -qq php7.0-ldap
apt-get install -qq php7.0-mcrypt
apt-get install -qq php7.0-mysql
apt-get install -qq php7.0-odbc
apt-get install -qq php7.0-opcache
apt-get install -qq php7.0-pgsql
apt-get install -qq php7.0-pspell
apt-get install -qq php7.0-readline
apt-get install -qq php7.0-recode
apt-get install -qq php7.0-sqlite
apt-get install -qq php7.0-tidy
apt-get install -qq php7.0-xsl
apt-get install -qq php7.0-xmlrpc

# apt-get install -qq php7.0-sphinx
# apt-get install -qq php7.0-imagick
# apt-get install -qq php7.0-mysqlnd


# MongoDB =====================================================================
sudo pecl install mongodb
echo 'extension=mongodb.so' | sudo tee /etc/php/mods-available/mongo.ini
ln -s /etc/php/mods-available/mongo.ini /etc/php/7.0/fpm/conf.d/mongo.ini
ln -s /etc/php/mods-available/mongo.ini /etc/php/7.0/cli/conf.d/mongo.ini


# GeoIP =======================================================================
# apt-get install -qq php7.0-geoip
sudo apt-get install libgeoip-dev
cd /tmp
git clone https://github.com/Zakay/geoip.git
cd geoip
phpize7.0
./configure --with-php-config=/usr/bin/php-config7.0
make
sudo make install
# Installing shared extensions:     /usr/lib/php/20151012/
echo 'extension=geoip.so' | sudo tee /etc/php/mods-available/geoip.ini
ln -s /etc/php/mods-available/geoip.ini /etc/php/7.0/fpm/conf.d/geoip.ini
ln -s /etc/php/mods-available/geoip.ini /etc/php/7.0/cli/conf.d/geoip.ini


# Memcached ===================================================================
# apt-get install -qq php7.0-memcached
apt-get install -y git pkg-config build-essential libmemcached-dev
cd /tmp
git clone https://github.com/php-memcached-dev/php-memcached.git
cd php-memcached
git checkout php7
phpize7.0
./configure --disable-memcached-sasl
make
sudo make install
echo 'extension=memcached.so' | sudo tee /etc/php/mods-available/memcached.ini
sudo ln -s /etc/php/mods-available/memcached.ini /etc/php/7.0/fpm/conf.d/memcached.ini
sudo ln -s /etc/php/mods-available/memcached.ini /etc/php/7.0/cli/conf.d/memcached.ini

# Redis =======================================================================
# apt-get install -qq php7.0-redis
apt-get -qq install re2c
cd /tmp
git clone -q https://github.com/phpredis/phpredis.git /tmp/php-redis/
cd /tmp/php-redis/
git checkout -q php7
phpize7.0
./configure
make
sudo make install
echo "extension=redis.so" | sudo tee /etc/php/mods-available/redis.ini
sudo ln -s /etc/php/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/redis.ini
sudo ln -s /etc/php/mods-available/redis.ini /etc/php/7.0/cli/conf.d/redis.ini

# Reload php-fpm to include the new changes ===================================
service php5.6-fpm restart
service php7.0-fpm restart

# Reload Nginx & Ajenti =======================================================
service nginx restart
service ajenti restart