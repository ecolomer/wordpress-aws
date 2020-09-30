#!/bin/bash
set -euo pipefail

echo "Ensuring correct permissions ..."
# If we want to run a read-only root filesystem, we need to mount a
# writable /tmp but ECS/Fargate 1.4.0 does not preserve underlying
# permissions when mounting ephemeral task storage. This is why
# we need to manually fixe the /tmp permissions
chmod 1777 /tmp

exec docker-entrypoint.sh "$@"
