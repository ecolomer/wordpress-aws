#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "Usage: $0 {bucket-name}\n"
  exit -1
fi

exec > /var/log/sync-to-s3.log
exec 2>&1

bucket=$1

aws s3 sync --delete /data/wp-content/ s3://$bucket/wp-content/