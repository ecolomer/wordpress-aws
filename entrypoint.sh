#!/bin/bash
set -euo pipefail

# WordPress image must have "nc" available for this to work
retries=10
while [ "$retries" -gt 0 ] && ! nc -z $WORDPRESS_DB_HOST 3306
do
  sleep 2
  ((retries--))
done
echo "Database ready!"

echo "Adding permissions"
chown -R www-data:www-data /var/www/html/wp-content &
find /var/www/html/wp-content -type d -exec chmod 0755 {} \; &
find /var/www/html/wp-content -type f -exec chmod 644 {} \; &
echo "Permissions added"

exec docker-entrypoint.sh "$@"
