#!/usr/bin/env bash
# https://gist.github.com/natsu90/208024d7a0ea37f0e48b
# 
# downgrade to php5.4 first
sudo apt-get install software-properties-common python-software-properties
sudo add-apt-repository ppa:ondrej/php5-oldstable -y
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install php5

# install ajenti
wget -O- https://raw.github.com/Eugeny/ajenti/master/scripts/install-ubuntu.sh | sudo sh

# install ajenti-v
sudo apt-get autoremove && sudo apt-get remove apache2*
sudo apt-get install ajenti-v ajenti-v-nginx ajenti-v-mysql ajenti-v-php-fpm php5-mysql

# install mongodb
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# install pymongo
sudo apt-get install python-pip build-essential python-dev
sudo pip install pymongo

# install mongo php driver
sudo apt-get install php5-dev php5-cli php-pear
sudo pecl install mongo
echo "extension=mongo.so" >> /etc/php5/cli/php.ini
echo "extension=mongo.so" >> /etc/php5/fpm/php.ini

# install csf firewall
sudo wget http://www.configserver.com/free/csf.tgz
sudo tar -xzf csf.tgz
sudo ufw disable
cd csf && sudo sh install.sh
csf -r

# install mcrypt
# sudo apt-get install php5-mcrypt
# echo "extension=mcrypt.so" >> /etc/php5/cli/php.ini
# echo "extension=mcrypt.so" >> /etc/php5/fpm/php.ini

# restart all
sudo service php5-fpm restart
sudo service nginx restart
sudo service ajenti restart

# install unzip
# sudo apt-get install unzip

# https://www.digitalocean.com/community/tutorials/how-to-install-laravel-with-nginx-on-an-ubuntu-12-04-lts-vps
# sudo chgrp -R www-data /srv/website
# sudo chmod -R 775 /srv/website/app/storage