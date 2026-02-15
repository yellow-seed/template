#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

GO_VERSION="1.23.5"

main() {
  ensure_path

  if command_exists go; then
    log "Go already installed: $(go version | awk '{print $3}')"
    ensure_gopath
    return 0
  fi

  if ! detect_arch; then
    return 0
  fi

  log "Installing Go ${GO_VERSION}..."
  local temp_dir
  temp_dir=$(mktemp -d)

  local tarball="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  local url="https://go.dev/dl/${tarball}"

  if ! download_file "$url" "$temp_dir/go.tar.gz"; then
    fail "failed to download Go ${GO_VERSION}"
    rm -rf "$temp_dir"
    return 1
  fi

  local go_install_dir=""
  if [ -n "${GO_INSTALL_DIR:-}" ]; then
    go_install_dir="$GO_INSTALL_DIR"
  elif [ -w "/usr/local" ] && [ "$INSTALL_PREFIX" = "/usr/local/bin" ]; then
    go_install_dir="/usr/local/go"
  else
    go_install_dir="$HOME/.local/go"
  fi

  rm -rf "$go_install_dir"
  mkdir -p "$go_install_dir"

  if tar -C "$go_install_dir" -xzf "$temp_dir/go.tar.gz" --strip-components=1; then
    if [[ ":$PATH:" != *":$go_install_dir/bin:"* ]]; then
      export PATH="$go_install_dir/bin:$PATH"
      if [ -n "$ENV_FILE" ]; then
        echo "export PATH=\"$go_install_dir/bin:\$PATH\"" >>"$ENV_FILE"
      fi
    fi
    log "Go ${GO_VERSION} installed successfully"
    ensure_gopath
  else
    fail "failed to extract Go"
  fi

  rm -rf "$temp_dir"
}

main "$@"
