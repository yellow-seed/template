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

  cat > "$WORK_DIR/bin/sudo" <<'SUDO'
#!/bin/bash
"$@"
SUDO
  chmod +x "$WORK_DIR/bin/sudo"

  export PATH="$WORK_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "install_packages runs apt-get update before install and creates stamp" {
  export APT_UPDATE_STAMP="$WORK_DIR/apt-update.stamp"

  run bash -c "source '$REPO_ROOT/scripts/installers/_common.sh'; install_packages curl"
  [ "$status" -eq 0 ]

  [ -f "$APT_UPDATE_STAMP" ]

  update_line=$(grep -n '^update -qq$' "$APT_GET_LOG" | head -n1 | cut -d: -f1)
  install_line=$(grep -n '^install -y curl$' "$APT_GET_LOG" | head -n1 | cut -d: -f1)

  [ -n "$update_line" ]
  [ -n "$install_line" ]
  [ "$update_line" -lt "$install_line" ]
}
