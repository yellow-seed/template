#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/installers/_common.sh"

SKIP_INSTALLERS="${SKIP_INSTALLERS:-}"
TEMP_ENV_FILE=""

should_skip() {
  local name="$1"
  [[ ",$SKIP_INSTALLERS," == *",$name,"* ]]
}

main() {
  log "Starting tool installation"
  ensure_path

  if [ -z "$ENV_FILE" ]; then
    TEMP_ENV_FILE=$(mktemp)
    ENV_FILE="$TEMP_ENV_FILE"
    export ENV_FILE
    trap 'rm -f "$TEMP_ENV_FILE"' EXIT
  fi

  if ! detect_arch; then
    return 0
  fi

  local installers=(
    shellcheck
    go
    shfmt
    actionlint
    node
    prettier
    helper-scripts
  )

  for installer in "${installers[@]}"; do
    if should_skip "$installer"; then
      log "Skipping $installer (SKIP_INSTALLERS)"
      continue
    fi

    if ! bash "$SCRIPT_DIR/installers/${installer}.sh"; then
      fail "$installer installer failed"
      continue
    fi

    if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
      # shellcheck disable=SC1090
      source "$ENV_FILE"
    fi
  done

  log "Tool installation completed"
}

main "$@"
