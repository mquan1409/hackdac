#!/usr/bin/env bash
# Start a persistent Ubuntu 24.04 container with this repository mounted.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="${HACKDAC_CONTAINER_NAME:-hackdac-ubuntu24}"
CONTAINER_IMAGE="${HACKDAC_CONTAINER_IMAGE:-ubuntu:24.04}"
CONTAINER_WORKSPACE="/workspace/hackdac"

docker_command() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  elif command -v sudo >/dev/null 2>&1; then
    DOCKER=(sudo docker)
  else
    echo "Docker is unavailable and sudo is not installed" >&2
    exit 1
  fi
}

docker_command

if "${DOCKER[@]}" container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  RUNNING="$("${DOCKER[@]}" container inspect --format '{{.State.Running}}' "$CONTAINER_NAME")"
  if [[ "$RUNNING" != "true" ]]; then
    "${DOCKER[@]}" start "$CONTAINER_NAME" >/dev/null
    echo "started container: $CONTAINER_NAME"
  else
    echo "container already running: $CONTAINER_NAME"
  fi
else
  "${DOCKER[@]}" run -d \
    --name "$CONTAINER_NAME" \
    --init \
    --workdir "$CONTAINER_WORKSPACE" \
    --volume "$REPO_ROOT:$CONTAINER_WORKSPACE" \
    "$CONTAINER_IMAGE" \
    sleep infinity >/dev/null
  echo "created container: $CONTAINER_NAME"
fi

echo "repository mount: $REPO_ROOT -> $CONTAINER_WORKSPACE"
echo "connect with: ./scripts/container_bash.sh"
