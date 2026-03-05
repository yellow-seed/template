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
	# When /usr/local/bin is not writable (e.g. non-root CI), install to $HOME/.local/bin
	if [ -w /usr/local/bin ]; then
		if ! curl -fsSL https://dotenvx.sh | sh; then
			fail "failed to install dotenvx"
			return 1
		fi
	else
		mkdir -p "$HOME/.local/bin"
		if ! curl -fsSL "https://dotenvx.sh?directory=$HOME/.local/bin" | sh; then
			fail "failed to install dotenvx"
			return 1
		fi
	fi

	# Detect user-local install path and update PATH before post-install check
	dotenvx_local="$HOME/.local/bin"
	if [ -x "$dotenvx_local/dotenvx" ] && [[ ":$PATH:" != *":$dotenvx_local:"* ]]; then
		export PATH="$dotenvx_local:$PATH"
		if [ -n "${ENV_FILE:-}" ]; then
			echo "export PATH=\"$dotenvx_local:\$PATH\"" >>"$ENV_FILE"
		fi
		hash -r 2>/dev/null || true
	fi

	if ! command_exists dotenvx; then
		fail "dotenvx command not found after install"
		return 1
	fi

	log "dotenvx installed successfully: $(dotenvx --version)"
}

main "$@"
