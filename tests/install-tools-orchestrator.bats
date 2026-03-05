#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  mkdir -p "$WORK_DIR/scripts/installers"

  cp "$REPO_ROOT/scripts/install-tools.sh" "$WORK_DIR/scripts/install-tools.sh"
  cp "$REPO_ROOT/scripts/installers/_common.sh" "$WORK_DIR/scripts/installers/_common.sh"

  export INSTALL_LOG="$WORK_DIR/installers.log"
  : >"$INSTALL_LOG"

  for installer in bats dotenvx qlty terraform; do
    cat >"$WORK_DIR/scripts/installers/${installer}.sh" <<SCRIPT
#!/bin/bash
echo "${installer}" >>"$INSTALL_LOG"
SCRIPT
    chmod +x "$WORK_DIR/scripts/installers/${installer}.sh"
  done
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "install-tools invokes terraform installer" {
  run bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "terraform" "$INSTALL_LOG"
  [ "$status" -eq 0 ]
}
