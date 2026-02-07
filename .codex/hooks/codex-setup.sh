#!/bin/bash
# Codex setup script
# This script provisions Codex-friendly tooling by chaining the
# gh, environment, and skills setup hooks.

set -euo pipefail

LOG_PREFIX="[codex-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

log "Starting Codex setup..."

log "1/4 Running gh CLI setup..."
bash "$REPO_ROOT/.codex/hooks/gh-setup.sh"

log "2/4 Running environment setup..."
bash "$REPO_ROOT/.codex/hooks/env-setup.sh"

log "3/4 Syncing skills directory..."
bash "$REPO_ROOT/.claude/hooks/skills-setup.sh"

log "4/4 Configuring git hooks..."
bash "$REPO_ROOT/scripts/setup-git-hooks.sh"

log "Codex setup completed successfully."
