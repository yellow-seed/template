#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/installers/_common.sh"

SKIP_INSTALLERS="${SKIP_INSTALLERS:-}"

should_skip() {
  local name="$1"
  local normalized

  normalized=",${SKIP_INSTALLERS// /},"
  [[ "$normalized" == *",$name,"* ]]
}

main() {
  local installers=(
    shellcheck
    go
    shfmt
    actionlint
    node
    prettier
    helper-scripts
  )

  log "Starting tool installation"
  ensure_path

  for installer in "${installers[@]}"; do
    if should_skip "$installer"; then
      log "Skipping $installer (SKIP_INSTALLERS)"
      continue
    fi

    bash "$SCRIPT_DIR/installers/${installer}.sh"
  done

  log "Tool installation completed"
}

main "$@"
