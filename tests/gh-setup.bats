#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/gh-setup.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  export GH_LOG="$WORK_DIR/gh.log"
  export GH_EXTENSIONS="$WORK_DIR/extensions.txt"
  : >"$GH_LOG"
  : >"$GH_EXTENSIONS"

  mkdir -p "$WORK_DIR/bin"
  cat >"$WORK_DIR/bin/gh" <<'GH'
#!/bin/bash
set -e

printf '%s\n' "$*" >>"$GH_LOG"

case "$1 $2" in
  "--version ")
    echo "gh version 9.9.9"
    ;;
  "extension list")
    cat "$GH_EXTENSIONS"
    ;;
  "extension install")
    echo "$3" >>"$GH_EXTENSIONS"
    ;;
esac
GH
  chmod +x "$WORK_DIR/bin/gh"

  export PATH="$WORK_DIR/bin:$PATH"
  export REMOTE_ENV_VAR="TEST_REMOTE"
  export TEST_REMOTE=true
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "gh-setup installs gh-sub-issue and gh-discussion extensions" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -x "yahsan2/gh-sub-issue" "$GH_EXTENSIONS"
  [ "$status" -eq 0 ]

  run grep -x "harakeishi/gh-discussion" "$GH_EXTENSIONS"
  [ "$status" -eq 0 ]
}

@test "gh-setup skips extension install when both extensions already exist" {
  cat >"$GH_EXTENSIONS" <<'EXT'
yahsan2/gh-sub-issue
harakeishi/gh-discussion
EXT

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run awk '/^extension install / { count++ } END { print count + 0 }' "$GH_LOG"
  [ "$status" -eq 0 ]
  [ "$output" -eq 0 ]
}
