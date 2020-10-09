#!/bin/bash
set -euo pipefail

echo "Ensuring correct permissions ..."
chown -R www-data:www-data /var/www/html/wp-content /var/log/pagespeed /var/cache/mod_pagespeed &
find /var/www/html/wp-content -type d -exec chmod 0755 {} \; &
find /var/www/html/wp-content -type f -exec chmod 0644 {} \; &

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