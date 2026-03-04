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

	log "Fetching latest bats-core version..."

	local version_json
	version_json=$(curl -fsSL https://api.github.com/repos/bats-core/bats-core/releases/latest 2>/dev/null) || {
		fail "failed to fetch latest bats-core release info"
		return 1
	}

	local version
	version=$(printf '%s' "$version_json" | grep '"tag_name"' | head -n1 | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')
	if [ -z "$version" ]; then
		fail "could not parse bats-core version from GitHub API response"
		return 1
	fi

	log "Installing bats-core ${version}..."

	local tmp_dir
	tmp_dir=$(mktemp -d)
	trap 'rm -rf "$tmp_dir"' EXIT

	local archive_url="https://github.com/bats-core/bats-core/archive/refs/tags/v${version}.tar.gz"
	local archive="$tmp_dir/bats-core.tar.gz"

	if ! download_file "$archive_url" "$archive"; then
		fail "failed to download bats-core"
		return 1
	fi

	tar -xzf "$archive" -C "$tmp_dir"

	local sudo_cmd
	sudo_cmd=$(use_sudo)

	# bats-core install.sh expects a prefix (e.g. /usr/local), not a bin dir.
	# It will install the bats binary to $prefix/bin/bats, so derive the
	# prefix from INSTALL_PREFIX by taking its parent directory.
	local prefix
	prefix=$(dirname "$INSTALL_PREFIX")

	if ! $sudo_cmd bash "$tmp_dir/bats-core-${version}/install.sh" "$prefix"; then
		fail "failed to install bats-core"
		return 1
	fi

	log "bats installed: $(bats --version)"
}

main "$@"
