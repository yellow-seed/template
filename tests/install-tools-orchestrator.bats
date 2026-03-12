#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  mkdir -p "$WORK_DIR/scripts/installers"
  mkdir -p "$WORK_DIR/bin"

  cp "$REPO_ROOT/scripts/install-tools.sh" "$WORK_DIR/scripts/install-tools.sh"
  cp "$REPO_ROOT/scripts/installers/_common.sh" "$WORK_DIR/scripts/installers/_common.sh"

  export INSTALL_LOG="$WORK_DIR/installers.log"
  export MISE_LOG="$WORK_DIR/mise.log"
  : >"$INSTALL_LOG"
  : >"$MISE_LOG"

  export PATH="$WORK_DIR/bin:$PATH"

  for installer in mise bats dotenvx qlty terraform; do
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

@test "install-tools falls back to individual installers when mise is skipped" {
  run env SKIP_INSTALLERS=mise bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "bats" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "dotenvx" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "terraform" "$INSTALL_LOG"
  [ "$status" -eq 0 ]
}

@test "install-tools runs mise install and qlty when mise is present" {
  cat >"$WORK_DIR/bin/mise" <<'MISE'
#!/bin/bash
echo "$*" >>"$MISE_LOG"
MISE
  chmod +x "$WORK_DIR/bin/mise"

  run bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "install" "$MISE_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "bats" "$INSTALL_LOG"
  [ "$status" -eq 1 ]

  run grep -x "dotenvx" "$INSTALL_LOG"
  [ "$status" -eq 1 ]

  run grep -x "terraform" "$INSTALL_LOG"
  [ "$status" -eq 1 ]
}

@test "install-tools skips qlty when requested in mise mode" {
  cat >"$WORK_DIR/bin/mise" <<'MISE'
#!/bin/bash
echo "$*" >>"$MISE_LOG"
MISE
  chmod +x "$WORK_DIR/bin/mise"

  run env SKIP_INSTALLERS=qlty bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "install" "$MISE_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -eq 1 ]
}
