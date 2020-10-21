#!/bin/bash
set -euo pipefail

echo -e "\nEnsuring correct permissions ..."
chown -R www-data:www-data /var/log/pagespeed /var/cache/mod_pagespeed &

retries=30
while [ "$retries" -gt 0 ] && ! [ -f /etc/apache2/ssl/certs/fullchain.pem ]; do
  echo -e "\nWaiting for TLS certificates to be available ..."
  sleep 10
  ((retries--))
done

if [ "$retries" -eq 0 ]; then
  echo -e "\nError: No TLS certificates for Apache found! Maybe letsencrypt had an issue."
  exit -1
fi

exec docker-entrypoint.sh "$@"