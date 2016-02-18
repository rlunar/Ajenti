#!/usr/bin/env bash

echo ">>> Installing RabbitMQ"

ROOT_USER="root"
ROOT_USER_PASS="P@\$\$w0r|)"

apt-get -y install erlang-nox
wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
apt-key add rabbitmq-signing-key-public.asc
echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list
apt-get update
apt-get install rabbitmq-server

rabbitmqctl add_user ${ROOT_USER} ${ROOT_USER_PASS}
rabbitmqctl set_permissions -p / $1 ".*" ".*" ".*"
