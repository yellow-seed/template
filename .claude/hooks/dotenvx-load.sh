#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_PATH="$REPO_ROOT/.env"

log_warn() {
	echo "[dotenvx-load] $*" >&2
}

if ! command -v dotenvx >/dev/null 2>&1; then
	log_warn "dotenvx is not installed; skipping .env load"
	exit 0
fi

if [ -z "${DOTENV_KEY:-}" ]; then
	log_warn "DOTENV_KEY is not set; skipping .env load"
	exit 0
fi

if [ ! -f "$ENV_PATH" ]; then
	log_warn ".env file not found at $ENV_PATH; skipping .env load"
	exit 0
fi

if ! eval "$(cd "$REPO_ROOT" && dotenvx get --format=shell)"; then
	log_warn "failed to load environment variables via dotenvx"
	exit 0
fi

log_warn "loaded environment variables from .env"
