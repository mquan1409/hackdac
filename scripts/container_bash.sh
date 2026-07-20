#!/usr/bin/env bash
# Open an interactive root shell in the persistent HackDAC Ubuntu container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="${HACKDAC_CONTAINER_NAME:-hackdac-ubuntu24}"
CONTAINER_WORKSPACE="/workspace/hackdac"

"$SCRIPT_DIR/container_start.sh"

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif command -v sudo >/dev/null 2>&1; then
  DOCKER=(sudo docker)
else
  echo "Docker is unavailable and sudo is not installed" >&2
  exit 1
fi

exec "${DOCKER[@]}" exec -it \
  --user root \
  --workdir "$CONTAINER_WORKSPACE" \
  "$CONTAINER_NAME" \
  /bin/bash
