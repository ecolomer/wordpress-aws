#!/bin/sh

if [ $# -ne 1 ]; then
  echo -e "Usage: $0 {bucket-name}\n"
  exit -1
fi

exec > /proc/1/fd/1
exec 2>&1

bucket=$1

/usr/local/bin/aws s3 sync --delete /data/wp-content/ s3://$bucket/wp-content/