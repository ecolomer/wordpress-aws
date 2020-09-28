#!/bin/bash
set -euo pipefail

echo "Ensuring correct permissions ..."
chown -R www-data:www-data /var/www/html/wp-content &
find /var/www/html/wp-content -type d -exec chmod 0755 {} \; &
find /var/www/html/wp-content -type f -exec chmod 0644 {} \; &

exec docker-entrypoint.sh "$@"
