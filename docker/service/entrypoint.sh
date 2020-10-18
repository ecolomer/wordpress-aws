#!/bin/bash
set -euo pipefail

echo -e "\nEnsuring correct permissions ..."
chown -R www-data:www-data /var/log/pagespeed /var/cache/mod_pagespeed &

exec docker-entrypoint.sh "$@"