#!/usr/bin/env bash
# Maintenance script: restore .env from the CODEX_REMOTE_ENV block in ~/.bashrc.
# Use this on sessions where .env was lost but ~/.bashrc still has the env vars.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
BASHRC="${HOME}/.bashrc"
BASHRC_BEGIN_MARKER="# BEGIN CODEX_REMOTE_ENV"
BASHRC_END_MARKER="# END CODEX_REMOTE_ENV"

LOG_PREFIX="[restore-env]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

log_error() {
	local message="$1"
	echo "${LOG_PREFIX} ERROR: ${message}" >&2
}

extract_env_from_bashrc() {
	[[ ! -f "${BASHRC}" ]] && return 1

	local in_block=0
	local found=0
	while IFS= read -r line; do
		if [[ "${line}" == "${BASHRC_BEGIN_MARKER}" ]]; then
			in_block=1
			continue
		fi
		if [[ "${line}" == "${BASHRC_END_MARKER}" ]]; then
			in_block=0
			continue
		fi
		if [[ ${in_block} -eq 1 && "${line}" =~ ^export\ ([A-Z_]+)=\"(.*)\"$ ]]; then
			printf '%s=%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
			found=1
		fi
	done < "${BASHRC}"

	[[ ${found} -eq 1 ]]
}

env_content="$(extract_env_from_bashrc)" || {
	log_error "No CODEX_REMOTE_ENV block found in ${BASHRC}"
	exit 1
}

if [[ -z "${env_content}" ]]; then
	log_error "CODEX_REMOTE_ENV block in ${BASHRC} is empty"
	exit 1
fi

umask 077
printf '%s\n' "${env_content}" > "${ENV_FILE}"

set -a
# shellcheck source=/dev/null
. "${ENV_FILE}"
set +a

log_info "Restored ${ENV_FILE} from ${BASHRC}"
