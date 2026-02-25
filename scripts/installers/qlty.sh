#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
	ensure_path

	if command_exists qlty; then
		log "qlty already installed: $(qlty --version)"
		return 0
	fi

	log "Installing qlty..."
	if ! curl -fsSL https://qlty.sh | sh; then
		fail "failed to install qlty"
		return 1
	fi

	local qlty_bin="$HOME/.qlty/bin"
	if [ -d "$qlty_bin" ] && [[ ":$PATH:" != *":$qlty_bin:"* ]]; then
		export PATH="$qlty_bin:$PATH"
		if [ -n "$ENV_FILE" ]; then
			echo "export PATH=\"$qlty_bin:\$PATH\"" >>"$ENV_FILE"
		fi
	fi

	log "qlty installed successfully: $(qlty --version)"
}

main "$@"
