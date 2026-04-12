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

if [ "${CODEX_REMOTE:-}" = "true" ]; then
	log "1/6 Removing git remote origin..."
	git -C "$REPO_ROOT" remote remove origin 2>/dev/null || true
else
	log "1/6 Skipping git remote removal (not a remote session)"
fi

log "2/6 Running gh CLI setup..."
bash "$REPO_ROOT/.codex/hooks/gh-setup.sh"


log "3/6 Installing development tools via scripts/install-tools.sh..."
INSTALL_PREFIX="${HOME}/.local/bin" \
ENV_FILE="${CODEX_ENV_FILE:-}" \
STRICT_MODE="false" \
	bash "$REPO_ROOT/scripts/install-tools.sh"

log "4/6 Running environment setup..."
CODEX_SKIP_TOOL_INSTALL=1 bash "$REPO_ROOT/.codex/hooks/env-setup.sh"

log "5/6 Syncing skills directory..."
bash "$REPO_ROOT/.claude/hooks/skills-setup.sh"

log "6/6 Configuring git hooks..."
bash "$REPO_ROOT/scripts/setup-git-hooks.sh"

log "Codex setup completed successfully."
