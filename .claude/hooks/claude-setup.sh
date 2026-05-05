#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE="${CLAUDE_SETUP_PROFILE:-default}"

LOG_PREFIX="[claude-setup]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

ensure_local_bin_in_path() {
	local local_bin="${HOME}/.local/bin"
	if [[ ":${PATH}:" != *":${local_bin}:"* ]]; then
		export PATH="${local_bin}:${PATH}"
	fi
}

setup_default() {
	log_info "Bootstrapping dotenvx..."
	bash "${REPO_ROOT}/.claude/hooks/bootstrap-dotenvx.sh"

	log_info "Bootstrapping gh..."
	bash "${REPO_ROOT}/.claude/hooks/bootstrap-gh.sh"
	ensure_local_bin_in_path

	log_info "Setting up remote environment..."
	bash "${REPO_ROOT}/.claude/hooks/setup-remote-env.sh"

	log_info "Running gh CLI setup..."
	bash "${REPO_ROOT}/.claude/hooks/gh-setup.sh"

	log_info "Syncing skills directory..."
	bash "${REPO_ROOT}/.claude/hooks/skills-setup.sh"

	log_info "Configuring git hooks..."
	bash "${REPO_ROOT}/scripts/setup-git-hooks.sh"
}

setup_full() {
	setup_default

	log_info "Installing full toolchain..."
	bash "${REPO_ROOT}/.claude/hooks/env-setup.sh"
}

setup_session() {
	log_info "Bootstrapping gh..."
	bash "${REPO_ROOT}/.claude/hooks/bootstrap-gh.sh"
	ensure_local_bin_in_path

	log_info "Setting up remote environment..."
	bash "${REPO_ROOT}/.claude/hooks/setup-remote-env.sh"

	log_info "Syncing skills directory..."
	bash "${REPO_ROOT}/.claude/hooks/skills-setup.sh"

	log_info "Configuring git hooks..."
	bash "${REPO_ROOT}/scripts/setup-git-hooks.sh"
}

log_info "Starting Claude setup (profile: ${PROFILE})..."

case "${PROFILE}" in
default)
	setup_default
	;;
full)
	setup_full
	;;
session)
	setup_session
	;;
*)
	log_info "Unknown profile: ${PROFILE}" >&2
	exit 1
	;;
esac

log_info "Claude setup completed (profile: ${PROFILE})."
