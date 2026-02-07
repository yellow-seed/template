#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export REMOTE_ENV_VAR="CLAUDE_CODE_REMOTE"
export ENV_FILE="${CLAUDE_ENV_FILE:-}"

bash "$REPO_ROOT/scripts/gh-setup.sh"

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  bash "$REPO_ROOT/scripts/setup-git-hooks.sh"
fi
