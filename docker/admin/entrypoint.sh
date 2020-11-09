#!/bin/bash
set -euo pipefail

echo "Ensuring correct permissions ..."
chown -R www-data:www-data /var/log/pagespeed /var/cache/mod_pagespeed &

exec docker-entrypoint.sh "$@"
