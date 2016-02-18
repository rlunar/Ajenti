#!/usr/bin/env bash

wget --quiet --output-document=tmp.conf https://raw.githubusercontent.com/rlunar/Ajenti/master/settings/sysctl.conf

cat tmp.conf >> /etc/sysctl.conf
