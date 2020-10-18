#!/bin/bash
set -euo pipefail

echo -e "\nEnsuring correct permissions ..."
chown -R 33:33 /wp-content
find /wp-content -type d -exec chmod 0755 {} \;
find /wp-content -type f -exec chmod 0644 {} \;

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
  mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e "CREATE DATABASE $WP_DATABASE;"
else
  echo -e "\nDatabase exists. Skipping ..."
fi

echo -e "\nChecking if WordPress user exists ..."
result=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -sse "SELECT 1 FROM mysql.user WHERE user = '$WP_USER';")
if [ "$result" != "1" ]; then
  echo "User does not exist. Creating ..."
  mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD <<-EOF
  GRANT ALL PRIVILEGES ON $WP_DATABASE.* TO "$WP_USER"@"%" IDENTIFIED BY "$WP_PASSWORD";
  FLUSH PRIVILEGES;
EOF
else
  echo -e "\nUser exists. Skipping ..."
fi