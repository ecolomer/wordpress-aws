#!/bin/sh
set -euo pipefail

yum install -y crontabs > /dev/null 2>&1

echo "* * * * *   root   sync-to-s3.sh $1" >> /etc/crontab
exec crond -n