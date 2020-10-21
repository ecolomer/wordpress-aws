#!/bin/sh
set -euo pipefail

/usr/bin/run-certbot.sh $1

cat <<EOF >> /etc/periodic/weekly/run-certbot.sh
#!/bin/sh

/usr/bin/run-certbot.sh $1
EOF

exec crond -f -l 8