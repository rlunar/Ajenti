#!/usr/bin/env bash


##############
# Base Items #
##############

# Provision Base Packages
scripts/base.sh

scripts/tunning.sh


###############
# Web Servers #
###############

# Provision Ajenti (Nginx/PHP/MySQL/NodeJS/Python)
scripts/ajenti.sh

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
#scripts/sphinxsearch.sh

# Search Server Administration (web-based)
# Install ElasticHQ
# scripts/elastichq.sh


####################
# In-Memory Stores #
####################

# Install Memcached
# scripts/memcaches.sh

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

# Install Nodejs
# scripts/nodejs.sh


##########################
# Frameworks and Tooling #
##########################

# Provision Composer
# scripts/composer.sh

# Install Mailcatcher
# http://mailcatcher.me/
# scripts/mailcatcher.sh

# Install Ansible
# scripts/ansible.sh

