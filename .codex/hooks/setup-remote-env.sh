#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_REMOTE="${REPO_ROOT}/.env.remote"

LOG_PREFIX="[setup-remote-env]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

log_error() {
	local message="$1"
	echo "${LOG_PREFIX} ERROR: ${message}" >&2
}

LOCAL_BIN="${HOME}/.local/bin"
if [[ ":${PATH}:" != *":${LOCAL_BIN}:"* ]]; then
	export PATH="${LOCAL_BIN}:${PATH}"
fi

if [[ ! -f ${ENV_REMOTE} ]]; then
	log_info ".env.remote not found, skipping remote env setup"
	exit 0
fi

if ! command -v dotenvx >/dev/null 2>&1; then
	log_info "dotenvx not found, skipping remote env setup"
	exit 0
fi

if [[ -z ${DOTENV_PRIVATE_KEY_REMOTE:-} && -z ${DOTENV_PRIVATE_KEY:-} ]]; then
	log_error "DOTENV_PRIVATE_KEY_REMOTE / DOTENV_PRIVATE_KEY not set"
	log_error "remote env must be loaded via dotenvx at command runtime"
	exit 0
fi

if ! (cd "${REPO_ROOT}" && dotenvx decrypt -f .env.remote >/dev/null); then
	log_error "failed to decrypt .env.remote with current DOTENV_PRIVATE_KEY*"
	exit 1
fi

log_info "Validated .env.remote decryption key"
log_info "Use dotenvx run -f .env.remote -- <command> to load remote env"
