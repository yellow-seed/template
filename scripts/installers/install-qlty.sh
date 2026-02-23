#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

QLTY_INSTALL_URL="https://qlty.sh"

main() {
  ensure_path

  if command_exists qlty; then
    log "qlty already installed: $(qlty --version)"
    return 0
  fi

  log "Installing qlty..."
  if ! curl -fsSL "$QLTY_INSTALL_URL" | sh; then
    fail "failed to install qlty via installer script"
    return 1
  fi

  local installed_binary=""
  for candidate in "$HOME/.qlty/bin/qlty" "$HOME/.local/share/qlty/bin/qlty"; do
    if [ -x "$candidate" ]; then
      installed_binary="$candidate"
      break
    fi
  done

  if [ -z "$installed_binary" ]; then
    fail "qlty binary was not found in expected install directories"
    return 1
  fi

  cp "$installed_binary" "$INSTALL_PREFIX/qlty"
  chmod +x "$INSTALL_PREFIX/qlty"
  log "qlty installed successfully"
}

main "$@"
