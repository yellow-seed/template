#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

PRETTIER_VERSION="3.4.2"

main() {
  ensure_path

  if command_exists prettier; then
    log "Prettier already installed: $(prettier --version)"
    return 0
  fi

  if ! command_exists npm; then
    fail "npm is required to install Prettier"
    return 1
  fi

  log "Installing Prettier v${PRETTIER_VERSION}..."
  if npm install -g "prettier@${PRETTIER_VERSION}"; then
    log "Prettier v${PRETTIER_VERSION} installed successfully"
  else
    fail "Failed to install Prettier"
    return 1
  fi
}

main "$@"
