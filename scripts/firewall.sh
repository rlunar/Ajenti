#!/usr/bin/env bash
#
# install csf firewall
sudo wget http://www.configserver.com/free/csf.tgz
sudo tar -xzf csf.tgz
sudo ufw disable
cd csf && sudo sh install.sh
csf -r
