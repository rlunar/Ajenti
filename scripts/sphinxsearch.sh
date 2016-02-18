#!/usr/bin/env bash

echo ">>> Installing Sphinx"

sphinxsearch_version="rel22"

# Add sphinxsearch repo
sudo add-apt-repository -y ppa:builds/sphinxsearch-${sphinxsearch_version}

# The usual updates
sudo apt-get update

# Install SphinxSearch
sudo apt-get install -qq sphinxsearch

# Create a base conf file (Altho we can't make any assumptions about its use)

# Stop searchd so we can change the config file
searchd --stop

# Move pid file since searchd will fail to start after reboot
sudo sed -i 's/sphinxsearch\/searchd.pid/searchd.pid/' /etc/sphinxsearch/sphinx.conf

# Start searchd
searchd