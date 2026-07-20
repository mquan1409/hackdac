#!/usr/bin/env bash
# Run inside the Ubuntu Docker container as root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_container_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "install_container.sh must run as root inside the container" >&2
    exit 1
  fi
  if [[ ! -f /.dockerenv && ! -f /run/.containerenv ]]; then
    echo "install_container.sh must run inside a container" >&2
    exit 1
  fi
}

require_container_root
exec "$SCRIPT_DIR/install_new.sh" "$@"
