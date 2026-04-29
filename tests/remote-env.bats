#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SETUP_SCRIPT="$REPO_ROOT/scripts/setup-remote-env"
GH_REMOTE_SCRIPT="$REPO_ROOT/scripts/gh-remote"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/repo/scripts" "$WORK_DIR/bin"
  cp "$SETUP_SCRIPT" "$WORK_DIR/repo/scripts/setup-remote-env" 2>/dev/null || true
  cp "$GH_REMOTE_SCRIPT" "$WORK_DIR/repo/scripts/gh-remote" 2>/dev/null || true

  cat >"$WORK_DIR/bin/dotenvx" <<'DOTENVX'
#!/bin/bash
set -euo pipefail

if [ "$1" != "run" ] || [ "$2" != "-f" ] || [ "$3" != ".env.remote" ] || [ "$4" != "--" ]; then
  printf 'unexpected dotenvx args: %s\n' "$*" >&2
  exit 2
fi

shift 4
GH_TOKEN="remote-token" EXTRA_SECRET="hidden" "$@"
DOTENVX
  chmod +x "$WORK_DIR/bin/dotenvx"

  cat >"$WORK_DIR/bin/gh" <<'GH'
#!/bin/bash
set -euo pipefail
printf 'GH_TOKEN=%s\n' "${GH_TOKEN:-}"
printf 'args=%s\n' "$*"
GH
  chmod +x "$WORK_DIR/bin/gh"

  export PATH="$WORK_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "setup-remote-env decrypts .env.remote into a private root .env with only GH_TOKEN" {
  [ -x "$SETUP_SCRIPT" ]
  cp "$SETUP_SCRIPT" "$WORK_DIR/repo/scripts/setup-remote-env"
  touch "$WORK_DIR/repo/.env.remote"

  run bash "$WORK_DIR/repo/scripts/setup-remote-env"
  [ "$status" -eq 0 ]

  run cat "$WORK_DIR/repo/.env"
  [ "$status" -eq 0 ]
  [ "$output" = "GH_TOKEN=remote-token" ]

  run grep -q "EXTRA_SECRET" "$WORK_DIR/repo/.env"
  [ "$status" -eq 1 ]

  if stat -c "%a" "$WORK_DIR/repo/.env" >/dev/null 2>&1; then
    mode="$(stat -c "%a" "$WORK_DIR/repo/.env")"
  else
    mode="$(stat -f "%Lp" "$WORK_DIR/repo/.env")"
  fi
  [ "$mode" = "600" ]
}

@test "setup-remote-env fails clearly when .env.remote is missing" {
  cp "$SETUP_SCRIPT" "$WORK_DIR/repo/scripts/setup-remote-env"

  run bash "$WORK_DIR/repo/scripts/setup-remote-env"
  [ "$status" -eq 1 ]
  [[ "$output" == *".env.remote is required"* ]]
}

@test "gh-remote sources generated root .env before running gh" {
  [ -x "$GH_REMOTE_SCRIPT" ]
  cp "$GH_REMOTE_SCRIPT" "$WORK_DIR/repo/scripts/gh-remote"
  printf 'GH_TOKEN=remote-token\n' >"$WORK_DIR/repo/.env"

  run bash "$WORK_DIR/repo/scripts/gh-remote" auth status
  [ "$status" -eq 0 ]
  [[ "$output" == *"GH_TOKEN=remote-token"* ]]
  [[ "$output" == *"args=auth status"* ]]
}

@test "gh-remote fails clearly when generated .env is missing" {
  cp "$GH_REMOTE_SCRIPT" "$WORK_DIR/repo/scripts/gh-remote"

  run bash "$WORK_DIR/repo/scripts/gh-remote" auth status
  [ "$status" -eq 1 ]
  [[ "$output" == *"Run scripts/setup-remote-env first"* ]]
}
