#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[gh-setup]"
COMMAND_TIMEOUT_SECONDS="${GH_SETUP_COMMAND_TIMEOUT_SECONDS:-30}"
export GH_PROMPT_DISABLED=1

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

run_with_timeout() {
	if command -v timeout >/dev/null 2>&1; then
		timeout "${COMMAND_TIMEOUT_SECONDS}" "$@"
	else
		"$@"
	fi
}

install_gh_extension() {
	local gh_cmd="$1"
	local extension_repo="$2"
	local installed_extensions="$3"
	local extension_name="${extension_repo#*/}"

	log_info "Checking ${extension_name} extension..."

	if grep -q "${extension_repo}" <<<"${installed_extensions}"; then
		log_info "${extension_name} extension already installed"
		return 0
	fi

	log_info "Installing ${extension_name} extension..."
	if run_with_timeout "${gh_cmd}" extension install "${extension_repo}" 2>/dev/null; then
		log_info "${extension_name} extension installed successfully"
	else
		log_info "Failed to install ${extension_name} extension (non-critical, continuing)"
	fi
}

install_gh_extensions() {
	local gh_cmd="$1"
	local installed_extensions=""

	if ! installed_extensions="$(run_with_timeout "${gh_cmd}" extension list 2>/dev/null)"; then
		log_info "Failed to list gh extensions (non-critical, continuing)"
	fi

	install_gh_extension "${gh_cmd}" "yahsan2/gh-sub-issue" "${installed_extensions}"
	install_gh_extension "${gh_cmd}" "harakeishi/gh-discussion" "${installed_extensions}"
}

if [[ -z ${REMOTE_ENV_VAR:-} ]]; then
	log_info "REMOTE_ENV_VAR is not set, skipping gh setup"
	exit 0
fi

REMOTE_ENV_VALUE="${!REMOTE_ENV_VAR:-}"
if [[ ${REMOTE_ENV_VALUE} != "true" ]]; then
	log_info "Not a remote session, skipping gh setup"
	exit 0
fi

log_info "Remote session detected, checking gh CLI..."

# gh is installed by mise; ensure shims are in PATH
MISE_SHIMS="${HOME}/.local/share/mise/shims"
if [[ -d ${MISE_SHIMS} && ":${PATH}:" != *":${MISE_SHIMS}:"* ]]; then
	export PATH="${MISE_SHIMS}:${PATH}"
fi

if ! command -v gh &>/dev/null; then
	log_info "gh CLI not found; run install-tools.sh first"
	exit 0
fi

log_info "gh CLI available: $(gh --version | head -1)"
install_gh_extensions "gh"
