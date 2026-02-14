#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

SHELLCHECK_VERSION="0.10.0"

main() {
  ensure_path
  detect_arch || return 0

  if command_exists shellcheck; then
    log "shellcheck already installed: $(shellcheck --version | head -2 | tail -1)"
    return 0
  fi

  log "Installing shellcheck..."
  if install_packages shellcheck; then
    log "shellcheck installed successfully via apt-get"
    return 0
  fi

  if [ -z "${SHELLCHECK_ARCH:-}" ]; then
    fail "shellcheck architecture not available"
    return 1
  fi

  local temp_dir
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  local archive="shellcheck-v${SHELLCHECK_VERSION}.linux.${SHELLCHECK_ARCH}.tar.xz"
  local url="https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/${archive}"

  if download_file "$url" "$temp_dir/shellcheck.tar.xz"; then
    if tar -xJf "$temp_dir/shellcheck.tar.xz" -C "$temp_dir"; then
      if [ -f "$temp_dir/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" ]; then
        cp "$temp_dir/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" "$INSTALL_PREFIX/shellcheck"
        chmod +x "$INSTALL_PREFIX/shellcheck"
        log "shellcheck installed successfully from release archive"
      else
        fail "shellcheck binary not found after extraction"
        return 1
      fi
    else
      fail "failed to extract shellcheck archive"
      return 1
    fi
  else
    fail "failed to download shellcheck archive"
    return 1
  fi
}

main "$@"
