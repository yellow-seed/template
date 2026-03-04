#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
	if command_exists bats; then
		log "bats already installed: $(bats --version)"
		return 0
	fi

	log "Installing bats..."
	install_packages bats

	log "bats installed: $(bats --version)"
}

main "$@"
