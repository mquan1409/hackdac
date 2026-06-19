#!/usr/bin/env bash
# Compatibility shim. The generated Caliptra environment now lives at:
#   hack_dac/caliptra_env.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file must be sourced, not executed." >&2
  echo "Use: source ${BASH_SOURCE[0]}" >&2
  exit 1
fi

_HACKDAC_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_HACKDAC_WORKSPACE_NAME="hack_dac"
_HACKDAC_ENV_FILE="$_HACKDAC_REPO_ROOT/$_HACKDAC_WORKSPACE_NAME/caliptra_env.sh"

if [[ ! -f "$_HACKDAC_ENV_FILE" ]]; then
  echo "missing $_HACKDAC_ENV_FILE; run ./scripts/setup_new.sh first" >&2
  unset _HACKDAC_REPO_ROOT _HACKDAC_WORKSPACE_NAME _HACKDAC_ENV_FILE
  return 1
fi

# shellcheck disable=SC1090
source "$_HACKDAC_ENV_FILE"
unset _HACKDAC_REPO_ROOT _HACKDAC_WORKSPACE_NAME _HACKDAC_ENV_FILE
