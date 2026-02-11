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

log "1/5 Removing git remote origin..."
git -C "$REPO_ROOT" remote remove origin 2>/dev/null || true

log "2/5 Running gh CLI setup..."
bash "$REPO_ROOT/.codex/hooks/gh-setup.sh"

log "3/5 Running environment setup..."
bash "$REPO_ROOT/.codex/hooks/env-setup.sh"

log "4/5 Syncing skills directory..."
bash "$REPO_ROOT/.claude/hooks/skills-setup.sh"

log "5/5 Configuring git hooks..."
bash "$REPO_ROOT/scripts/setup-git-hooks.sh"

log "Codex setup completed successfully."
