#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

main() {
  ensure_path

  if command_exists node && command_exists npm; then
    log "Node.js already installed: $(node --version)"
    log "npm already installed: $(npm --version)"
    return 0
  fi

  log "Installing Node.js and npm..."
  if install_packages nodejs npm; then
    log "Node.js and npm installed successfully via apt-get"
    return 0
  fi

  if command_exists nvm; then
    if nvm install --lts; then
      log "Node.js installed successfully via nvm"
      return 0
    fi
  fi

  fail "Failed to install Node.js and npm"
}

main "$@"
