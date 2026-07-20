#!/usr/bin/env bash
# Run inside the Ubuntu Docker container as root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "setup_container.sh must run as root inside the container" >&2
  exit 1
fi
if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
  echo "setup_container.sh must run inside a container" >&2
  exit 1
fi

exec "$SCRIPT_DIR/setup_new.sh" "$@"
