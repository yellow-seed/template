#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
	ensure_path

	if command_exists terraform; then
		log "terraform already installed: $(terraform version | head -n1)"
		return 0
	fi

	if ! command_exists curl && ! command_exists wget; then
		fail "curl or wget is required to install terraform"
		return 1
	fi

	detect_arch || return 1
	local arch="$GO_ARCH"
	local mise_version
	mise_version=$(get_mise_tool_version terraform || true)
	local version="${TERRAFORM_VERSION:-${mise_version:-1.11.4}}"
	local os="linux"
	local zip_name="terraform_${version}_${os}_${arch}.zip"
	local download_url="https://releases.hashicorp.com/terraform/${version}/${zip_name}"

	log "Installing terraform ${version} for ${os}/${arch}..."

	if ! command_exists unzip; then
		log "unzip not found, attempting to install"
		install_packages unzip || return 1
	fi

	tmp_dir=$(mktemp -d)
	trap 'rm -rf "${tmp_dir:-}"' EXIT

	local archive="$tmp_dir/$zip_name"
	if ! download_file "$download_url" "$archive"; then
		fail "failed to download terraform archive"
		return 1
	fi

	if ! unzip -q "$archive" -d "$tmp_dir"; then
		fail "failed to extract terraform archive"
		return 1
	fi

	if [ ! -f "$tmp_dir/terraform" ]; then
		fail "terraform binary not found in archive"
		return 1
	fi

	local target="$INSTALL_PREFIX/terraform"
	local sudo_cmd
	sudo_cmd=$(use_sudo)

	if ! $sudo_cmd cp "$tmp_dir/terraform" "$target"; then
		fail "failed to install terraform binary"
		return 1
	fi

	if ! $sudo_cmd chmod +x "$target"; then
		fail "failed to mark terraform executable"
		return 1
	fi

	hash -r 2>/dev/null || true

	if ! command_exists terraform; then
		fail "terraform command not found after install"
		return 1
	fi

	log "terraform installed successfully: $(terraform version | head -n1)"
}

main "$@"
