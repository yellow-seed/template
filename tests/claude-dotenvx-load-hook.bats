#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/.claude/hooks/dotenvx-load.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/.claude/hooks" "$WORK_DIR/bin"
  cp "$SCRIPT" "$WORK_DIR/.claude/hooks/dotenvx-load.sh"

  export PATH="$WORK_DIR/bin:$PATH"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "dotenvx-load exits successfully when dotenvx is missing" {
  run bash "$WORK_DIR/.claude/hooks/dotenvx-load.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dotenvx is not installed"* ]]
}

@test "dotenvx-load exits successfully when DOTENV_KEY is missing" {
  cat >"$WORK_DIR/bin/dotenvx" <<'DOTENVX'
#!/bin/bash
exit 0
DOTENVX
  chmod +x "$WORK_DIR/bin/dotenvx"

  run bash "$WORK_DIR/.claude/hooks/dotenvx-load.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOTENV_KEY is not set"* ]]
}

@test "dotenvx-load exits successfully when .env is missing" {
  cat >"$WORK_DIR/bin/dotenvx" <<'DOTENVX'
#!/bin/bash
exit 0
DOTENVX
  chmod +x "$WORK_DIR/bin/dotenvx"

  export DOTENV_KEY="dummy-key"

  run bash "$WORK_DIR/.claude/hooks/dotenvx-load.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".env file not found"* ]]
}

@test "dotenvx-load evaluates dotenvx output when prerequisites are met" {
  cat >"$WORK_DIR/bin/dotenvx" <<'DOTENVX'
#!/bin/bash
if [ "$1" = "get" ] && [ "$2" = "--format=shell" ]; then
  echo "export LOADED_FROM_DOTENVX=ok"
  exit 0
fi
exit 1
DOTENVX
  chmod +x "$WORK_DIR/bin/dotenvx"

  touch "$WORK_DIR/.env"
  export DOTENV_KEY="dummy-key"

  run bash -c 'source "$1" && echo "$LOADED_FROM_DOTENVX"' _ "$WORK_DIR/.claude/hooks/dotenvx-load.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok"* ]]
}
