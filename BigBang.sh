#!/usr/bin/env bash


##############
# Base Items #
##############

# Provision Base Packages
# scripts/base.sh

# Server Tunning
# scripts/tunning.sh

# Server Firewall
# scripts/firewall.sh


###############
# Web Servers #
###############

# Provision Ajenti (Nginx/PHP/MySQL/NodeJS/Python)
# scripts/ajenti.sh

# Provision PHP
# scripts/php.sh


#############
# Databases #
#############

# Provision SQLite
# scripts/sqlite.sh

# Provision MongoDB
# scripts/mongodb.sh

# Provision PostgreSQL
# scripts/pgsql.sh


##################
# Search Servers #
##################

# Install Elasticsearch
# scripts/elasticsearch.sh

# Install SphinxSearch
# scripts/sphinxsearch.sh

# Search Server Administration (web-based)
# NOT GOOD X X X X X X X
# Install ElasticHQ
# scripts/elastichq.sh
# NOT GOOD X X X X X X X

####################
# In-Memory Stores #
####################

# Install Memcached
# scripts/memcached.sh

# Provision Redis (with journaling and persistence)
# scripts/redis.sh


###################
# Utility (queue) #
###################

# Install Beanstalkd
# scripts/beanstalkd.sh

# Install Supervisord
# scripts/supervisord.sh

# Install Kibana
# scripts/kibana.sh

# Install RabbitMQ
# https://github.com/rabbitmq/rabbitmq-tutorials
# scripts/rabbitmq.sh


########################
# Additional Languages #
########################

# NOT GOOD X X X X X X X
# Install Nodejs
# scripts/nodejs.sh
# NOT GOOD X X X X X X X

##########################
# Frameworks and Tooling #
##########################

# NOT GOOD X X X X X X X
# Provision Composer
# scripts/composer.sh
# NOT GOOD X X X X X X X

# Install Mailcatcher
# http://mailcatcher.me/
# scripts/mailcatcher.sh

# Install Ansible
# scripts/ansible.sh

# restart all
sudo service php5-fpm restart
sudo service nginx restart
sudo service ajenti restart