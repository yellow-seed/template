#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -z "${GH_SETUP_TOKEN:-}" ]; then
  if [ -n "${CLAUDE_GH_AUTH:-}" ]; then
    export GH_SETUP_TOKEN="${CLAUDE_GH_AUTH}"
  elif [ -n "${GH_TOKEN:-}" ]; then
    export GH_SETUP_TOKEN="${GH_TOKEN}"
  elif [ -n "${GITHUB_TOKEN:-}" ]; then
    export GH_SETUP_TOKEN="${GITHUB_TOKEN}"
  fi
fi

unset GH_TOKEN
unset GITHUB_TOKEN

export REMOTE_ENV_VAR="CLAUDE_CODE_REMOTE"
export ENV_FILE="${CLAUDE_ENV_FILE:-}"

bash "$REPO_ROOT/scripts/gh-setup.sh"

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  bash "$REPO_ROOT/scripts/setup-git-hooks.sh"
fi
