#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_REMOTE="${REPO_ROOT}/.env.remote"
ENV_FILE="${REPO_ROOT}/.env"

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

decrypt_env() {
	if [[ ! -f ${ENV_REMOTE} ]]; then
		log_info ".env.remote not found, skipping env decryption"
		return 0
	fi

	if [[ -z ${DOTENV_PRIVATE_KEY_REMOTE:-} ]]; then
		log_info "DOTENV_PRIVATE_KEY_REMOTE not set, skipping env decryption"
		return 0
	fi

	if ! command -v dotenvx >/dev/null 2>&1; then
		log_info "dotenvx not found, skipping env decryption"
		return 0
	fi

	log_info "Decrypting .env.remote..."
	cd "${REPO_ROOT}"
	# shellcheck disable=SC2016
	dotenvx run -f .env.remote -- sh -c 'umask 077; printf "GH_TOKEN=%s\n" "$GH_TOKEN" > .env'

	if [[ ! -s ${ENV_FILE} ]]; then
		log_error "failed to generate .env from .env.remote"
		return 1
	fi

	log_info "Generated ${ENV_FILE}"
}

source_env() {
	if [[ ! -f ${ENV_FILE} ]]; then
		return 0
	fi

	set -a
	# shellcheck source=/dev/null
	. "${ENV_FILE}"
	set +a
	log_info "Sourced ${ENV_FILE}"
}

setup_bashrc() {
	local bashrc="${HOME}/.bashrc"
	mkdir -p "${HOME}"
	touch "${bashrc}"

	# shellcheck disable=SC2016
	if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "${bashrc}"; then
		# shellcheck disable=SC2016
		echo 'export PATH="$HOME/.local/bin:$PATH"' >>"${bashrc}"
		log_info "Added ~/.local/bin to PATH in ~/.bashrc"
	fi

	if ! grep -qF "${ENV_FILE}" "${bashrc}"; then
		echo "[ -f \"${ENV_FILE}\" ] && set -a && . \"${ENV_FILE}\" && set +a" >>"${bashrc}"
		log_info "Added .env source to ~/.bashrc"
	fi
}

decrypt_env
source_env
setup_bashrc

log_info "Remote env setup completed."
