#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
	ensure_path

	if command_exists dotenvx; then
		log "dotenvx already installed: $(dotenvx --version)"
		return 0
	fi

	if ! command_exists curl; then
		fail "curl is required to install dotenvx but was not found"
		return 1
	fi

	log "Installing dotenvx..."
	if ! curl -fsSL https://dotenvx.sh | sh; then
		fail "failed to install dotenvx"
		return 1
	fi

	# Some installers place binaries in user-local locations (e.g. $HOME/.local/bin)
	# that may not be on PATH in non-interactive shells. Try to detect such installs
	# and update PATH before performing the post-install command_exists check.
	for candidate in "$HOME/.local/bin/dotenvx"; do
		if [ -x "$candidate" ]; then
			dotenvx_dir=$(dirname "$candidate")
			if [[ ":$PATH:" != *":$dotenvx_dir:"* ]]; then
				export PATH="$dotenvx_dir:$PATH"
				if [ -n "${ENV_FILE:-}" ]; then
					echo "export PATH=\"$dotenvx_dir:\$PATH\"" >>"$ENV_FILE"
				fi
			fi
			hash -r 2>/dev/null || true
			break
		fi
	done

	if ! command_exists dotenvx; then
		fail "dotenvx command not found after install"
		return 1
	fi

	log "dotenvx installed successfully: $(dotenvx --version)"
}

main "$@"
