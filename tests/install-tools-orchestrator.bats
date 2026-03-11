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

  cat >"$WORK_DIR/scripts/installers/mise.sh" <<'SCRIPT'
#!/bin/bash
echo "mise-installer" >>"$INSTALL_LOG"
cat >"$WORK_DIR/bin/mise" <<'MISE'
#!/bin/bash
echo "mise-install" >>"$INSTALL_LOG"
MISE
chmod +x "$WORK_DIR/bin/mise"
SCRIPT
  chmod +x "$WORK_DIR/scripts/installers/mise.sh"

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

@test "install-tools runs mise installer then mise install and qlty installer" {
  run env -i PATH="$WORK_DIR/bin" HOME="$HOME" INSTALL_LOG="$INSTALL_LOG" WORK_DIR="$WORK_DIR" bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "mise-installer" "$INSTALL_LOG"
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
  run env -i PATH="$WORK_DIR/bin" HOME="$HOME" INSTALL_LOG="$INSTALL_LOG" WORK_DIR="$WORK_DIR" SKIP_INSTALLERS="qlty" bash "$WORK_DIR/scripts/install-tools.sh"
  [ "$status" -eq 0 ]

  run grep -x "mise-installer" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "mise-install" "$INSTALL_LOG"
  [ "$status" -eq 0 ]

  run grep -x "qlty" "$INSTALL_LOG"
  [ "$status" -ne 0 ]
}
