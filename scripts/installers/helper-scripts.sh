#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/_common.sh"

install_helper_script() {
  local script_name="$1"
  local dest_name="$2"
  local source_path="$REPO_ROOT/scripts/${script_name}.sh"
  local dest_path="$INSTALL_PREFIX/$dest_name"

  if [ -x "$dest_path" ]; then
    log "$dest_name already installed"
    return 0
  fi

  if [ -f "$source_path" ]; then
    cp "$source_path" "$dest_path"
    chmod +x "$dest_path"
    log "$dest_name installed"
  else
    fail "$source_path not found"
  fi
}

main() {
  ensure_path
  install_helper_script "lint-shell" "lint-shell"
  install_helper_script "lint-docs" "lint-docs"
}

main "$@"
