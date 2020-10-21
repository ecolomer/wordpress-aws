#!/bin/sh

if [ $# -ne 1 ]; then
  echo -e "Usage: $0 {dns-name}\n"
  exit 1
fi

exec > /proc/1/fd/1
exec 2>&1

dnsname=$1

# Ensure required directories/files are available
mkdir -p /data/letsencrypt/.well-known/acme-challenge/
touch /data/letsencrypt/.well-known/acme-challenge/.live

# Check if acme-challenge endpoint is publicly available
retries=30
while [ "$retries" -gt 0 ] && ! (wget -S "https://$dnsname/.well-known/acme-challenge/.live" 2>&1 | grep -q 'HTTP/1.1 200'); do
  echo -e "\nWaiting for web server to be available on ALB ..."
  sleep 10
  retries=$((retries-1))
done

# Exit if acme-challenge could not be retrieved
if [ "$retries" -eq 0 ]; then
  echo -e "\nError: Could not connect to letsencrypt acme-challenge endpoint!"
  exit 1
fi

# Run certbot to generate certificates
certbot certonly --webroot --webroot-path=/data/letsencrypt -d $dnsname --agree-tos --keep-until-expiring --register-unsafely-without-email --staging

# Link certificates to preset Apache location
mkdir -p /etc/letsencrypt/certs && cd /etc/letsencrypt/certs
ln -sf ../live/$dnsname/fullchain.pem fullchain.pem
ln -sf ../live/$dnsname/privkey.pem privkey.pem
