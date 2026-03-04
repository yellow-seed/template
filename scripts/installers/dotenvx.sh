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

	log "Installing dotenvx..."
	if ! curl -sfS https://dotenvx.sh | sh; then
		fail "failed to install dotenvx"
		return 1
	fi

	if ! command_exists dotenvx; then
		fail "dotenvx command not found after install"
		return 1
	fi

	log "dotenvx installed successfully: $(dotenvx --version)"
}

main "$@"
