#!/bin/bash

echo "${TIMEZONE}" > /etc/timezone
rm -f /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get -y upgrade && apt-get update
apt-get install -y chrony && sed -i -e '/pool /i server 169.254.169.123 prefer iburst' /etc/chrony/chrony.conf && systemctl restart chrony
apt-get install -y unzip && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&
  unzip awscliv2.zip && ./aws/install && rm -rf aws*
apt-get install -y apt-transport-https && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io && usermod -aG docker ubuntu
curl -sSL "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
apt-get install -y amazon-ecr-credential-helper
mkdir -p /root/.docker && echo '{ "credsStore": "ecr-login" }' > /root/.docker/config.json
cp -r /root/.docker /home/ubuntu/ && chown -R ubuntu.ubuntu /home/ubuntu/.docker
mkdir -p /data