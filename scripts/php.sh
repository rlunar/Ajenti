#!/usr/bin/env bash
#
echo ">>> Installing PHP"
apt-get install -qq dbus
apt-get install -qq php5-common
apt-get install -qq php5-cli
apt-get install -qq php-pear
apt-get install -qq php5-curl
apt-get install -qq php5-gd
apt-get install -qq php5-gmp
apt-get install -qq php5-imagick
apt-get install -qq php5-intl
apt-get install -qq php5-json
apt-get install -qq php5-mysqlnd
apt-get install -qq php5-pgsql
apt-get install -qq php5-redis
apt-get install -qq php5-sqlite
apt-get install -qq php5-xsl

apt-get install -qq php5-memcached

# install mcrypt
apt-get install php5-mcrypt
echo "extension=mcrypt.so" >> /etc/php5/cli/php.ini
echo "extension=mcrypt.so" >> /etc/php5/fpm/php.ini

# restart all
service php5-fpm restart
service nginx restart
service ajenti restart
