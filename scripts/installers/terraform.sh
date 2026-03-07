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
	local version="${TERRAFORM_VERSION:-1.11.4}"
	version="${version#v}"

	local os
	case "$(uname -s)" in
	Linux)
		os="linux"
		;;
	Darwin)
		os="darwin"
		;;
	*)
		fail "unsupported operating system: $(uname -s). This installer supports Linux and macOS (Darwin) only."
		return 1
		;;
	esac

	local zip_name="terraform_${version}_${os}_${arch}.zip"
	local download_url="https://releases.hashicorp.com/terraform/${version}/${zip_name}"

	log "Installing terraform ${version} for ${os}/${arch}..."

	if ! command_exists unzip; then
		log "unzip not found, attempting to install"
		install_packages unzip || return 1
	fi

	local tmp_dir
	tmp_dir=$(mktemp -d)
	trap 'rm -rf "${tmp_dir:-}"' EXIT

	local archive="$tmp_dir/$zip_name"
	if ! download_file "$download_url" "$archive"; then
		fail "failed to download terraform archive"
		return 1
	fi

	local checksums_url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_SHA256SUMS"
	local checksums_file="$tmp_dir/terraform_${version}_SHA256SUMS"
	if ! download_file "$checksums_url" "$checksums_file"; then
		fail "failed to download terraform checksums"
		return 1
	fi
	if ! (
		cd "$tmp_dir" &&
			grep " ${zip_name}\$" "$checksums_file" | sha256sum -c -
	); then
		fail "terraform archive checksum verification failed"
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

	local tf_version
	if ! tf_version=$(terraform version 2>&1 | head -n1); then
		fail "terraform binary installed but failed to run: ${tf_version}"
		return 1
	fi

	log "terraform installed successfully: ${tf_version}"
}

main "$@"
