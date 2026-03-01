#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
	log "Installing bats-core and helper libraries..."
	if ! install_packages bats bats-support bats-assert; then
		fail "failed to install bats packages"
		return 1
	fi

	log "bats-core and helper libraries installed successfully"
}

main "$@"
