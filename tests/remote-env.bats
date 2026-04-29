#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/gh-setup.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/repo/scripts" "$WORK_DIR/bin"
  cp "$SCRIPT" "$WORK_DIR/repo/scripts/gh-setup.sh"

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
  export REMOTE_ENV_VAR="TEST_REMOTE"
  export TEST_REMOTE=true
  export DOTENV_PRIVATE_KEY_REMOTE="test-key"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "gh-setup decrypts .env.remote into a private root .env with only GH_TOKEN" {
  touch "$WORK_DIR/repo/.env.remote"

  run bash "$WORK_DIR/repo/scripts/gh-setup.sh"
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

@test "gh-setup skips env decryption when .env.remote is missing" {
  run bash "$WORK_DIR/repo/scripts/gh-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".env.remote not found"* ]]
}

@test "gh-setup skips env decryption when DOTENV_PRIVATE_KEY_REMOTE is not set" {
  touch "$WORK_DIR/repo/.env.remote"
  unset DOTENV_PRIVATE_KEY_REMOTE

  run bash "$WORK_DIR/repo/scripts/gh-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOTENV_PRIVATE_KEY_REMOTE not set"* ]]
}
