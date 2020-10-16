#!/bin/bash

sed -i -e "/ZONE/s|UTC|${TIMEZONE}|" /etc/sysconfig/clock
rm /etc/localtime && ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
yum install -y unzip && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && ./aws/install && rm -rf aws*
mkdir -p /data