#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Keep tokens out of inherited process environments and inject only for gh commands.
if [ -z "${GH_SETUP_TOKEN:-}" ]; then
  if [ -n "${CODEX_GH_AUTH:-}" ]; then
    export GH_SETUP_TOKEN="${CODEX_GH_AUTH}"
  elif [ -n "${GH_TOKEN:-}" ]; then
    export GH_SETUP_TOKEN="${GH_TOKEN}"
  elif [ -n "${GITHUB_TOKEN:-}" ]; then
    export GH_SETUP_TOKEN="${GITHUB_TOKEN}"
  fi
fi

unset GH_TOKEN
unset GITHUB_TOKEN

export REMOTE_ENV_VAR="CODEX_REMOTE"
export ENV_FILE="${CODEX_ENV_FILE:-}"

exec bash "$REPO_ROOT/scripts/gh-setup.sh"
