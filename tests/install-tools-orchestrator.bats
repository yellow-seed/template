#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  mkdir -p "$WORK_DIR/scripts/installers" "$WORK_DIR/bin"

  cp "$REPO_ROOT/scripts/install-tools.sh" "$WORK_DIR/scripts/install-tools.sh"
  cp "$REPO_ROOT/scripts/installers/_common.sh" "$WORK_DIR/scripts/installers/_common.sh"

  export INSTALL_LOG="$WORK_DIR/installers.log"
  : >"$INSTALL_LOG"

  for cmd in bash dirname mkdir mktemp rm id touch; do
    ln -s "$(command -v "$cmd")" "$WORK_DIR/bin/$cmd"
  done

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

@test "install-tools uses individual installers when mise is unavailable" {
  run env -i PATH="$WORK_DIR/bin" HOME="$HOME" INSTALL_LOG="$INSTALL_LOG" bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "terraform" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "mise" "$INSTALL_LOG"
  [ "$status" -eq 0 ]
}

@test "install-tools runs mise install and qlty installer when mise is available" {
  cat >"$WORK_DIR/bin/mise" <<'MISE'
#!/bin/bash
echo "mise-install" >>"$INSTALL_LOG"
MISE
  chmod +x "$WORK_DIR/bin/mise"

  run env -i PATH="$WORK_DIR/bin" HOME="$HOME" INSTALL_LOG="$INSTALL_LOG" bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "mise-install" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "terraform" "$INSTALL_LOG"
  [ "$status" -ne 0 ]

  run grep -x "bats" "$INSTALL_LOG"
  [ "$status" -ne 0 ]
}

@test "install-tools skips qlty when requested in mise mode" {
  cat >"$WORK_DIR/bin/mise" <<'MISE'
#!/bin/bash
echo "mise-install" >>"$INSTALL_LOG"
MISE
  chmod +x "$WORK_DIR/bin/mise"

  run env -i PATH="$WORK_DIR/bin" HOME="$HOME" INSTALL_LOG="$INSTALL_LOG" SKIP_INSTALLERS="qlty" bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "mise-install" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -ne 0 ]
}
