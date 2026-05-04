#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_REMOTE="${REPO_ROOT}/.env.remote"
ENV_FILE="${REPO_ROOT}/.env"

BASHRC="${HOME}/.bashrc"
BASHRC_BEGIN_MARKER="# BEGIN CODEX_REMOTE_ENV"
BASHRC_END_MARKER="# END CODEX_REMOTE_ENV"

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

# Write KEY=VALUE pairs from vars_file as export lines into a marked block in ~/.bashrc.
# Replaces any existing block idempotently.
write_env_to_bashrc() {
	local vars_file="$1"

	touch "${BASHRC}"

	local new_block="${BASHRC_BEGIN_MARKER}"$'\n'
	while IFS='=' read -r key value; do
		[[ -z ${key} || ${key} == \#* ]] && continue
		new_block+="export ${key}=\"${value}\""$'\n'
	done <"${vars_file}"
	new_block+="${BASHRC_END_MARKER}"

	local tmp_file
	tmp_file="$(mktemp)"

	awk -v begin="${BASHRC_BEGIN_MARKER}" -v end="${BASHRC_END_MARKER}" '
		$0 == begin { skip=1; next }
		$0 == end   { skip=0; next }
		!skip        { print }
	' "${BASHRC}" >"${tmp_file}"

	printf '\n%s\n' "${new_block}" >>"${tmp_file}"
	mv "${tmp_file}" "${BASHRC}"

	log_info "Wrote env vars to ${BASHRC}"
}

setup_bashrc_path() {
	mkdir -p "${HOME}"
	touch "${BASHRC}"
	# shellcheck disable=SC2016
	local path_line='export PATH="$HOME/.local/bin:$PATH"'
	if ! grep -qF "${path_line}" "${BASHRC}"; then
		printf '\n%s\n' "${path_line}" >>"${BASHRC}"
		log_info "Added ~/.local/bin to PATH in ~/.bashrc"
	fi
}

write_env_source_to_bashrc() {
	if ! grep -qF "${ENV_FILE}" "${BASHRC}"; then
		printf '\n[ -f %s ] && . %s\n' "${ENV_FILE}" "${ENV_FILE}" >>"${BASHRC}"
		log_info "Added .env source to ~/.bashrc"
	fi
}

decrypt_env() {
	if [[ -s ${ENV_FILE} ]]; then
		log_info "${ENV_FILE} already exists, skipping env decryption"
		return 0
	fi

	if [[ ! -f ${ENV_REMOTE} ]]; then
		log_info ".env.remote not found, skipping env decryption"
		return 0
	fi

	if [[ -z ${DOTENV_PRIVATE_KEY_REMOTE:-} && -z ${DOTENV_PRIVATE_KEY:-} ]]; then
		log_info "DOTENV_PRIVATE_KEY_REMOTE / DOTENV_PRIVATE_KEY not set, skipping env decryption"
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

	write_env_to_bashrc "${ENV_FILE}"
	write_env_source_to_bashrc
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

setup_bashrc_path

if ! decrypt_env; then
	log_error "env decryption failed, continuing without remote env"
fi

source_env

log_info "Remote env setup completed."
