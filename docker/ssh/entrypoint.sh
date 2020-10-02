#!/bin/bash
set -euo pipefail

# Check for available public SSH key
if [ -z ${SSH_KEY:+x} ]; then
        echo "Error: no SSH public key specified!"
        exit -1
fi

# Setup SSH auth file
mkdir -p /root/.ssh && echo "$SSH_KEY" > /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys

# Run SSH daemon in foreground
exec /usr/sbin/sshd -D -e