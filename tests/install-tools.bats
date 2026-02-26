#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
COMMON_SCRIPT="$REPO_ROOT/scripts/installers/_common.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
  export PATH="$TEST_DIR:$PATH"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "install_packages runs apt-get update when stamp file does not exist" {
  cat > "$TEST_DIR/apt-get" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >>"$APT_GET_LOG"
exit 0
MOCK
  chmod +x "$TEST_DIR/apt-get"

  export APT_GET_LOG="$TEST_DIR/apt.log"

  run bash -c '
    source "$0"
    APT_UPDATE_STAMP="$1/stamp"
    install_packages curl
  ' "$COMMON_SCRIPT" "$TEST_DIR"

  [ "$status" -eq 0 ]
  grep -q '^update -qq$' "$APT_GET_LOG"
  grep -q '^install -y curl$' "$APT_GET_LOG"
  [ -f "$TEST_DIR/stamp" ]
}
