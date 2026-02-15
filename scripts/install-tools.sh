#!/bin/bash
set -u
set -o pipefail

ORCHESTRATOR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$ORCHESTRATOR_DIR/installers/_common.sh"

SKIP_INSTALLERS="${SKIP_INSTALLERS:-}"

should_skip() {
  local name="$1"
  local token

  IFS=',' read -r -a skip_items <<<"$SKIP_INSTALLERS"
  for token in "${skip_items[@]}"; do
    token="${token#${token%%[![:space:]]*}}"
    token="${token%${token##*[![:space:]]}}"
    if [ "$token" = "$name" ]; then
      return 0
    fi
  done

  return 1
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
  local had_failure=false

  log "Starting tool installation"
  ensure_path

  for installer in "${installers[@]}"; do
    if should_skip "$installer"; then
      log "Skipping $installer (SKIP_INSTALLERS)"
      continue
    fi

    if ! bash "$ORCHESTRATOR_DIR/installers/${installer}.sh"; then
      had_failure=true
      fail "Installer failed: $installer"
      log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
    fi
  done

  if [ "$had_failure" = "true" ]; then
    log "Tool installation completed with errors"
    return 1
  fi

  log "Tool installation completed"
}

main "$@"
