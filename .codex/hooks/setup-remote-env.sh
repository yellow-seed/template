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

run_with_timeout() {
	local timeout_seconds="$1"
	shift

	if command -v timeout >/dev/null 2>&1; then
		timeout --kill-after=1s "${timeout_seconds}" "$@"
		return "$?"
	fi

	"$@" &
	local command_pid="$!"

	(
		sleep "${timeout_seconds}"
		if kill -0 "${command_pid}" 2>/dev/null; then
			kill "${command_pid}" 2>/dev/null || true
			sleep 1
			kill -9 "${command_pid}" 2>/dev/null || true
		fi
	) &
	local watchdog_pid="$!"

	local status
	set +e
	wait "${command_pid}"
	status="$?"
	set -e

	kill "${watchdog_pid}" 2>/dev/null || true
	wait "${watchdog_pid}" 2>/dev/null || true

	if [[ ${status} -eq 143 || ${status} -eq 137 ]]; then
		return 124
	fi
	return "${status}"
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
	local gh_token
	if ! gh_token="$(run_with_timeout "${SETUP_REMOTE_ENV_TIMEOUT_SECONDS:-60}" dotenvx get GH_TOKEN -f .env.remote --strict --no-ops)"; then
		log_error "dotenvx decryption timed out or failed"
		return 1
	fi

	if [[ -z ${gh_token} ]]; then
		log_error "GH_TOKEN is empty in .env.remote"
		return 1
	fi

	umask 077
	printf "GH_TOKEN=%s\n" "${gh_token}" >"${ENV_FILE}"

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
		echo "if [ -f \"${ENV_FILE}\" ]; then set -a; . \"${ENV_FILE}\"; set +a; fi" >>"${bashrc}"
		log_info "Added .env source to ~/.bashrc"
	fi
}

decrypt_env
source_env
setup_bashrc

log_info "Remote env setup completed."
