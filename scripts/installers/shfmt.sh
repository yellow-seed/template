#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

SHFMT_VERSION="3.12.0"

main() {
  ensure_path

  if command_exists shfmt; then
    log "shfmt already installed: $(shfmt --version)"
    return 0
  fi

  if ! command_exists go; then
    fail "Go is required to install shfmt"
    return 1
  fi

  ensure_gopath
  log "Installing shfmt v${SHFMT_VERSION}..."
  if GOBIN="$INSTALL_PREFIX" go install "mvdan.cc/sh/v3/cmd/shfmt@v${SHFMT_VERSION}"; then
    log "shfmt v${SHFMT_VERSION} installed successfully"
  else
    fail "failed to install shfmt"
    return 1
  fi
}

main "$@"
