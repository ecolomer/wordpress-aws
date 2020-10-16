#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "Usage: $0 {bucket-name}\n"
  exit -1
fi

exec > /var/log/backup-to-s3.log
exec 2>&1

bucket=$1

echo -e "\nBuilding backup package..."

DATE=$(date +%Y%m%d-%H%M%S)
tar zcf wp-content.$DATE.tar.gz -C /data/wp-content .

if [ $? -gt 0 ]; then
  exit -1
fi

echo -e "\nUploading to S3..."
aws s3 cp wp-content.$DATE.tar.gz s3://$bucket/

echo -e "\nCleaning up..."
rm wp-content.$DATE.tar.gz