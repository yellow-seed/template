#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  export APT_GET_LOG="$WORK_DIR/apt-get.log"

  mkdir -p "$WORK_DIR/bin"

  cat > "$WORK_DIR/bin/apt-get" <<'APT'
#!/bin/bash
printf '%s\n' "$*" >>"$APT_GET_LOG"
exit 0
APT
  chmod +x "$WORK_DIR/bin/apt-get"

  export PATH="$WORK_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "bats installer installs bats and helper libraries via apt" {
  export APT_UPDATE_STAMP="$WORK_DIR/apt-update.stamp"

  run bash "$REPO_ROOT/scripts/installers/bats.sh"
  [ "$status" -eq 0 ]

  grep -q '^update -qq$' "$APT_GET_LOG"
  grep -q '^install -y bats bats-support bats-assert$' "$APT_GET_LOG"
}
