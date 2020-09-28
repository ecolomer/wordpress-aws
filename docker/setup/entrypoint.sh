#!/bin/bash
set -euo pipefail

echo -e "\nChecking database connectivity ..."
retries=10
while [ "$retries" -gt 0 ] && ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD  -e ";"; do
  sleep 3
  ((retries--))
done

if [ "$retries" -eq 0 ]; then
  echo -e "\nError: Could not connect to RDS service!"
  exit -1
fi

echo -e "\nChecking if database exists ..."
if ! mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "use $WP_DATABASE;" > /dev/null 2>&1; then
  echo "Database does not exist. Creating ..."
  mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD <<-EOF
  CREATE DATABASE $WP_DATABASE;
  GRANT ALL PRIVILEGES ON $WP_DATABASE.* TO "$WP_USER"@"%" IDENTIFIED BY "$WP_PASSWORD";
  FLUSH PRIVILEGES;
EOF
else
  echo -e "\nDatabase exists. Skipping ..."
fi