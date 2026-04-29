#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

LOG_PREFIX="[env-setup]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

log_error() {
	local message="$1"
	echo "${LOG_PREFIX} ERROR: ${message}" >&2
}

setup_env_from_remote() {
	local env_remote="${REPO_ROOT}/.env.remote"
	local env_file="${REPO_ROOT}/.env"

	if [[ ! -f "${env_remote}" ]]; then
		log_info ".env.remote not found, skipping env decryption"
		return 0
	fi

	if [[ -z "${DOTENV_PRIVATE_KEY_REMOTE:-}" ]]; then
		log_info "DOTENV_PRIVATE_KEY_REMOTE not set, skipping env decryption"
		return 0
	fi

	if ! command -v dotenvx >/dev/null 2>&1; then
		log_info "dotenvx not found, skipping env decryption"
		return 0
	fi

	log_info "Decrypting .env.remote..."
	cd "${REPO_ROOT}"
	dotenvx run -f .env.remote -- sh -c 'umask 077; printf "GH_TOKEN=%s\n" "$GH_TOKEN" > .env'

	if [[ ! -s "${env_file}" ]]; then
		log_error "failed to generate .env from .env.remote"
		return 1
	fi

	log_info "Generated ${env_file}"

	set -a
	# shellcheck source=/dev/null
	. "${env_file}"
	set +a
}

log_info "Installing tools..."
bash "${SCRIPT_DIR}/install-tools.sh"

log_info "Setting up environment from remote..."
setup_env_from_remote

log_info "Environment setup completed."
