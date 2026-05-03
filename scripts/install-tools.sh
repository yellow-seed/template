#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/installers/_common.sh"

main() {
	log "Installing mise..."
	bash "$SCRIPT_DIR/installers/mise.sh"

	local mise_bin="$HOME/.local/bin"
	if [[ ":$PATH:" != *":$mise_bin:"* ]]; then
		export PATH="$mise_bin:$PATH"
	fi

	log "Installing tools via mise..."
	(cd "$REPO_ROOT" && mise install)

	local shims_dir="$HOME/.local/share/mise/shims"
	if [[ ":$PATH:" != *":$shims_dir:"* ]]; then
		export PATH="$shims_dir:$PATH"
	fi
	if [[ -n ${ENV_FILE:-} ]]; then
		echo "export PATH=\"$shims_dir:\$PATH\"" >>"$ENV_FILE"
	fi

	log "Installing helper scripts..."
	bash "$SCRIPT_DIR/installers/helper-scripts.sh"

	log "Tool installation completed"
}

main "$@"
