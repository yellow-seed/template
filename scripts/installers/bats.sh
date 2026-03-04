#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

BATS_VERSION="${BATS_VERSION:-1.11.1}"

main() {
	if command_exists bats; then
		log "bats already installed: $(bats --version)"
		return 0
	fi

	log "Installing bats-core ${BATS_VERSION}..."

	local tmp_dir
	tmp_dir=$(mktemp -d)
	trap 'rm -rf "$tmp_dir"' EXIT

	local archive_url="https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz"
	local archive="$tmp_dir/bats-core.tar.gz"

	if ! download_file "$archive_url" "$archive"; then
		fail "failed to download bats-core"
		return 1
	fi

	tar -xzf "$archive" -C "$tmp_dir"

	local sudo_cmd
	sudo_cmd=$(use_sudo)

	if ! $sudo_cmd bash "$tmp_dir/bats-core-${BATS_VERSION}/install.sh" "$INSTALL_PREFIX"; then
		fail "failed to install bats-core"
		return 1
	fi

	log "bats installed: $(bats --version)"
}

main "$@"
