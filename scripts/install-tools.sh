#!/usr/bin/env bash
set -euo pipefail

ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ORCHESTRATOR_DIR/installers/_common.sh"

append_path() {
	local path_entry="$1"

	if [[ ":$PATH:" != *":$path_entry:"* ]]; then
		export PATH="$path_entry:$PATH"
	fi
	if [[ -n ${ENV_FILE:-} ]]; then
		echo "export PATH=\"$path_entry:\$PATH\"" >>"$ENV_FILE"
	fi
	if [[ -n ${GITHUB_PATH:-} ]]; then
		echo "$path_entry" >>"$GITHUB_PATH"
	fi
	if [[ ${PERSIST_TO_BASHRC:-false} == "true" ]]; then
		mkdir -p "$HOME"
		touch "$HOME/.bashrc"
		if ! grep -F "export PATH=\"$path_entry:\$PATH\"" "$HOME/.bashrc" >/dev/null 2>&1; then
			echo "export PATH=\"$path_entry:\$PATH\"" >>"$HOME/.bashrc"
		fi
	fi
}

run_step() {
	local description="$1"
	shift

	log "$description"
	if "$@"; then
		return 0
	fi

	fail "$description failed"
	if [[ $STRICT_MODE == "true" ]]; then
		return 1
	fi
	return 0
}

install_mise_tools() {
	(
		cd "$REPO_ROOT"
		export MISE_YES=1
		export MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS:+${MISE_TRUSTED_CONFIG_PATHS}:}${REPO_ROOT}"
		mise install
	)
}

main() {
	run_step "Installing mise..." bash "$ORCHESTRATOR_DIR/installers/mise.sh"

	local mise_bin="$HOME/.local/bin"
	append_path "$mise_bin"

	run_step "Installing tools via mise..." install_mise_tools

	local shims_dir="$HOME/.local/share/mise/shims"
	append_path "$shims_dir"

	run_step "Installing helper scripts..." bash "$ORCHESTRATOR_DIR/installers/helper-scripts.sh"

	log "Tool installation completed"
}

main "$@"
