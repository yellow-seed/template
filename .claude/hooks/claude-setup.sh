#!/bin/bash
# Codex setup script
# This script provisions Codex-friendly tooling by chaining the
# gh, environment, and skills setup hooks.

set -euo pipefail

LOG_PREFIX="[claude-setup]"

log() {
	echo "$LOG_PREFIX $1" >&2
}

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

log "Starting Claude setup..."

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
	log "1/5 Removing git remote origin..."
	git -C "$REPO_ROOT" remote remove origin 2>/dev/null || true
else
	log "1/5 Skipping git remote removal (not a remote session)"
fi

log "2/5 Running gh CLI setup..."
bash "$REPO_ROOT/.claude/hooks/gh-setup.sh"

log "3/5 Running environment setup..."
bash "$REPO_ROOT/.claude/hooks/env-setup.sh"

log "4/5 Syncing skills directory..."
bash "$REPO_ROOT/.claude/hooks/skills-setup.sh"

log "5/5 Configuring git hooks..."
bash "$REPO_ROOT/scripts/setup-git-hooks.sh"

log "Claude setup completed successfully."
