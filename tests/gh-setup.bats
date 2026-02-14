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

  run grep -q "GH_TOKEN=secret-token GITHUB_TOKEN=secret-token" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup prefers GH_SETUP_TOKEN over all token env vars" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  export GH_SETUP_TOKEN="from-gh-setup"
  export CODEX_GH_AUTH="from-codex"
  export CLAUDE_GH_AUTH="from-claude"
  export GH_TOKEN="from-gh-token"
  export GITHUB_TOKEN="from-github-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN=from-gh-setup GITHUB_TOKEN=from-gh-setup" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup prefers CODEX_GH_AUTH over lower-priority vars" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_SETUP_TOKEN
  export CODEX_GH_AUTH="from-codex"
  export CLAUDE_GH_AUTH="from-claude"
  export GH_TOKEN="from-gh-token"
  export GITHUB_TOKEN="from-github-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN=from-codex GITHUB_TOKEN=from-codex" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup prefers CLAUDE_GH_AUTH over GH_TOKEN and GITHUB_TOKEN" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_SETUP_TOKEN
  unset CODEX_GH_AUTH
  export CLAUDE_GH_AUTH="from-claude"
  export GH_TOKEN="from-gh-token"
  export GITHUB_TOKEN="from-github-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN=from-claude GITHUB_TOKEN=from-claude" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup prefers GH_TOKEN over GITHUB_TOKEN" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_SETUP_TOKEN
  unset CODEX_GH_AUTH
  unset CLAUDE_GH_AUTH
  export GH_TOKEN="from-gh-token"
  export GITHUB_TOKEN="from-github-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN=from-gh-token GITHUB_TOKEN=from-gh-token" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup falls back to GITHUB_TOKEN when it is the only token" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_SETUP_TOKEN
  unset CODEX_GH_AUTH
  unset CLAUDE_GH_AUTH
  unset GH_TOKEN
  export GITHUB_TOKEN="from-github-token"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN=from-github-token GITHUB_TOKEN=from-github-token" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}

@test "gh-setup runs without token" {
  export REMOTE_ENV_VAR="CODEX_REMOTE"
  export CODEX_REMOTE="true"
  unset GH_TOKEN
  unset GITHUB_TOKEN

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -q "GH_TOKEN= GITHUB_TOKEN=" "$GH_TEST_LOG"
  [ "$status" -eq 0 ]
}
