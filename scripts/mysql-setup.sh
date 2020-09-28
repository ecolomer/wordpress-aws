#!/bin/bash
set -euo pipefail

if [ $# -gt 2 ]; then
  echo -e "\nSetup WordPress database and user permissions"
  echo -e "All required parameters are read from AWS SSM Parameter Store. If no dump is provided, an empty database is created.\n"
  echo -e "Usage: $0 [database-ssm-prefix] [mysql-dump]\n"
  exit -1
fi

SSM_PREFIX=${1:-/wordpress/database}
MYSQL_DUMP=${2:-}

echo -e "\nRetrieving SSM parameters ..."
DB_HOST=`aws ssm get-parameter --name $SSM_PREFIX/writer-endpoint --query "Parameter.Value" --output text`
DB_USER=`aws ssm get-parameter --name $SSM_PREFIX/masteruser --query "Parameter.Value" --output text`
DB_PASSWORD=`aws ssm get-parameter --name $SSM_PREFIX/masterpassword --with-decryption --query "Parameter.Value" --output text`
WP_DATABASE=`aws ssm get-parameter --name $SSM_PREFIX/wpdatabase --query "Parameter.Value" --output text`
WP_USER=`aws ssm get-parameter --name $SSM_PREFIX/wpuser --query "Parameter.Value" --output text`
WP_PASSWORD=`aws ssm get-parameter --name $SSM_PREFIX/wppassword --with-decryption --query "Parameter.Value" --output text`

# Prepare MySQL configuration file
cat > /tmp/mysql.cnf <<-EOF
[client]
user=$DB_USER
password=$DB_PASSWORD
EOF

echo -e "\nChecking database connectivity ..."
retries=10
while [ "$retries" -gt 0 ] && ! mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST -e ";"; do
  sleep 3
  ((retries--))
done

if [ "$retries" -eq 0 ]; then
  echo -e "\nError: Could not connect to RDS service!"
  rm -f /tmp/mysql.cnf
  exit -1
fi

if [ -n "$MYSQL_DUMP" ]; then
  if mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST -e "use $WP_DATABASE;" > /dev/null 2>&1; then
    echo "Database exists. Dropping ..."
    mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST -e "drop database $WP_DATABASE;"
  fi

  echo "Restoring database ..."
  mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST < $MYSQL_DUMP
else
  if ! mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST -e "use $WP_DATABASE;" > /dev/null 2>&1; then
    echo "Database does not exist. Creating ..."
    mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST -e "CREATE DATABASE $WP_DATABASE;"
  else
    echo "Database exists. Skipping ..."
  fi
fi

echo -e "\nCreating WordPress database user and granting access ...\n"

mysql --defaults-file=/tmp/mysql.cnf -h $DB_HOST <<-EOF
GRANT ALL PRIVILEGES ON $WP_DATABASE.* TO "$WP_USER"@"%" IDENTIFIED BY "$WP_PASSWORD";
FLUSH PRIVILEGES;
EOF

rm -f /tmp/mysql.cnf