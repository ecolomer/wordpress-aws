#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "Usage: $0 {dns-name}\n"
  exit -1
fi

exec > /var/log/run-certbot.log
exec 2>&1

dnsname=$1

# Ensure required directories/files are available
mkdir -p /data/letsencrypt/etc/archive /data/letsencrypt/etc/live /data/letsencrypt/var-lib \
  /data/letsencrypt/var-log /data/letsencrypt/www/.well-known/acme-challenge
touch /data/letsencrypt/www/.well-known/acme-challenge/.live

# Check if acme-challenge endpoint is publicly available
retries=30
while [ "$retries" -gt 0 ] && ! (curl -sSI "http://$dnsname/.well-known/acme-challenge/.live" | grep -q 'HTTP/1.1 200'); do
  echo -e "\nWaiting for web server to be available on ALB ..."
  sleep 10
  ((retries--))
done

# Exit if acme-challenge could not be retrieved
if [ "$retries" -eq 0 ]; then
  echo -e "\nError: Could not connect to letsencrypt acme-challenge endpoint!"
  exit -1
fi

# Run certbot to generate certificates
docker run --rm -v /data/letsencrypt/etc:/etc/letsencrypt -v /data/letsencrypt/var-lib:/var/lib/letsencrypt \
  -v /data/letsencrypt/var-log:/var/log/letsencrypt -v /data/letsencrypt/www:/data/letsencrypt certbot/certbot certonly \
  --webroot --webroot-path=/data/letsencrypt -d $dnsname --keep-until-expiring --agree-tos --register-unsafely-without-email --staging

# Link certificates to preset Apache location
mkdir -p /data/letsencrypt/etc/certs && cd /data/letsencrypt/etc/certs
ln -sf ../live/$dnsname/fullchain.pem fullchain.pem
ln -sf ../live/$dnsname/privkey.pem privkey.pem