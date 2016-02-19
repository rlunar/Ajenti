#!/usr/bin/env bash
#
uname -a

# Update Package List
apt-get update

# Update System Packages
apt-get -y upgrade

echo "Setting Timezone & Locale to EST & en_US.UTF-8"
sudo ln -sf /usr/share/zoneinfo/EST /etc/localtime
sudo apt-get install -qq language-pack-en
apt-get install -qq language-pack-en-base
sudo locale-gen en_US
sudo update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# Install base packages
echo ">>> Installing Base Packages"

# Antivirus
apt-get install -qq clamav
apt-get install -qq clamav-daemon
freshclam
service clamav-daemon start

# Basic Tools ##############################################################
apt-get install -qq build-essential 
apt-get install -qq software-properties-common
apt-get install -qq python-software-properties

apt-get install -qq ack-grep
apt-get install -qq bzip2
apt-get install -qq dos2unix
apt-get install -qq cachefilesd
apt-get install -qq curl
apt-get install -qq gcc
apt-get install -qq git-core
apt-get install -qq libmcrypt4
apt-get install -qq libpcre3-dev
apt-get install -qq make
apt-get install -qq nano
apt-get install -qq ntp
apt-get install -qq ntpdate
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

cp -pf /etc/apt/sources.list /etc/apt/sources.list_bak

