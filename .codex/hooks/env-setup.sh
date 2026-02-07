#!/bin/bash
# Development Environment Setup Script for Codex
# This script delegates to scripts/install-tools.sh with Codex-friendly defaults.

set -e

LOG_PREFIX="[env-setup]"

log() {
  echo "$LOG_PREFIX $*" >&2
}

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

log "Starting development environment setup..."

INSTALL_PREFIX="${HOME}/.local/bin"
ENV_FILE="${CODEX_ENV_FILE:-}"
STRICT_MODE="false"

export INSTALL_PREFIX
export ENV_FILE
export STRICT_MODE

bash "$REPO_ROOT/scripts/install-tools.sh"

log "Development environment setup completed successfully!"
