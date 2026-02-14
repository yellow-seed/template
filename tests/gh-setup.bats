#!/usr/bin/env bats

# Tests for scripts/gh-setup.sh – token scoping for gh commands

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/gh-setup.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  export FAKE_BIN="$WORK_DIR/bin"
  mkdir -p "$FAKE_BIN"

  cat >"$FAKE_BIN/gh" <<'GH'
#!/bin/bash
printf 'GH_TOKEN=%s GITHUB_TOKEN=%s CMD=%s\n' "${GH_TOKEN:-}" "${GITHUB_TOKEN:-}" "$*" >>"${GH_TEST_LOG}"
if [ "$1" = "--version" ]; then
  echo 'gh version 2.62.0'
  exit 0
fi
if [ "$1" = "extension" ] && [ "$2" = "list" ]; then
  echo 'yahsan2/gh-sub-issue'
  exit 0
fi
exit 0
GH
  chmod +x "$FAKE_BIN/gh"

  export PATH="$FAKE_BIN:$PATH"
  export GH_TEST_LOG="$WORK_DIR/gh.log"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "gh-setup injects token only when available" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  export GH_TOKEN="secret-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run rg -n "GH_TOKEN=secret-token GITHUB_TOKEN=secret-token" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup runs without token" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_TOKEN
  unset GITHUB_TOKEN

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run rg -n "GH_TOKEN= GITHUB_TOKEN=" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}
