#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export REMOTE_ENV_VAR="CODEX_REMOTE"
export ENV_FILE="${CODEX_ENV_FILE:-}"

exec bash "$REPO_ROOT/scripts/gh-setup.sh"
