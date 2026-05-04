#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[gh-setup]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

install_gh_extension() {
	local gh_cmd="$1"
	local extension_repo="$2"
	local extension_name="${extension_repo#*/}"

	log_info "Checking ${extension_name} extension..."

	if "${gh_cmd}" extension list 2>/dev/null | grep -q "${extension_repo}"; then
		log_info "${extension_name} extension already installed"
		return 0
	fi

	log_info "Installing ${extension_name} extension..."
	if "${gh_cmd}" extension install "${extension_repo}" 2>/dev/null; then
		log_info "${extension_name} extension installed successfully"
	else
		log_info "Failed to install ${extension_name} extension (non-critical, continuing)"
	fi
}

install_gh_extensions() {
	local gh_cmd="$1"
	install_gh_extension "${gh_cmd}" "yahsan2/gh-sub-issue"
	install_gh_extension "${gh_cmd}" "harakeishi/gh-discussion"
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

if [[ -z ${GH_TOKEN:-} ]]; then
	log_info "GH_TOKEN is not set; skipping gh extension setup"
	exit 0
fi

install_gh_extensions "gh"
