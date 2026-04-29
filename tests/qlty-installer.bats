#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/installers/qlty.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/bin"
  cat >"$WORK_DIR/bin/curl" <<'CURL'
#!/bin/bash
cat <<'INSTALLER'
#!/bin/sh
mkdir -p "$HOME/.qlty/bin"
cat >"$HOME/.qlty/bin/qlty" <<'QLTY'
#!/bin/sh
echo "qlty 9.9.9"
QLTY
chmod +x "$HOME/.qlty/bin/qlty"
INSTALLER
CURL
  chmod +x "$WORK_DIR/bin/curl"

  export HOME="$WORK_DIR/home"
  export INSTALL_PREFIX="$WORK_DIR/install"
  export PATH="$WORK_DIR/bin:/usr/bin:/bin"
  export STRICT_MODE=true
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "qlty installer exposes qlty from INSTALL_PREFIX" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  [ -x "$INSTALL_PREFIX/qlty" ]

  run "$INSTALL_PREFIX/qlty" --version
  [ "$status" -eq 0 ]
  [ "$output" = "qlty 9.9.9" ]
}
