#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

ACTIONLINT_VERSION="1.7.5"

main() {
  ensure_path
  ensure_gopath

  if command_exists actionlint; then
    log "actionlint already installed: $(actionlint --version | head -1)"
    return 0
  fi

  if ! command_exists go; then
    fail "Go is required to install actionlint"
    return 1
  fi

  log "Installing actionlint v${ACTIONLINT_VERSION}..."
  if GOBIN="$INSTALL_PREFIX" go install "github.com/rhysd/actionlint/cmd/actionlint@v${ACTIONLINT_VERSION}"; then
    log "actionlint v${ACTIONLINT_VERSION} installed successfully"
  else
    fail "failed to install actionlint"
  fi
}

main "$@"
